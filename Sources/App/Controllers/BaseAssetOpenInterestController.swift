import Fluent
import Vapor

struct BaseAssetOpenInterestController {
    let depth: Int = 730 //want to get the data for two years
    
    func load(_ req: Request, baseAssetId: UUID, date: Date) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        
        let defaultStartDate = Calendar.current.date(byAdding: DateComponents(day: -1 * self.depth), to: Date())!
        
        return UpdateInfoController.loadUpdateInfo(req, group: BaseAssetOpenInterest.schema, defaultDate: defaultStartDate).flatMap({
            updateInfo -> EventLoopFuture<[BaseAssetOpenInterest]> in
            
            let startDate = updateInfo.getDate()
            
            if (!updateInfo.isToday() && !updateInfo.longOperationInProgress()) {
                return self.loadFromCSV(req, endDate: date, startDate: startDate, baseAssetId: baseAssetId, returnDate: date, updateInfo: updateInfo)
            } else {
                return self.loadFromDB(req, baseAssetId: baseAssetId, date: date)
            }
        })
    }
    
    // @MARK: load from CSV file
    func loadFromCSV(_ req: Request, endDate: Date, startDate: Date, baseAssetId: UUID, returnDate: Date? = nil, updateInfo: UpdateInfo) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        let promise = req.eventLoop.makePromise(of: [BaseAssetOpenInterest].self)
        let queue = EventLoopFutureQueue(eventLoop: req.eventLoop)
        var resultSetFuture = [EventLoopFuture<[BaseAssetOpenInterest]>]()
        
        _ = updateInfo.startLongOperation(req).map({
            DateHelper.iterateMidnights(startDate: startDate, endDate: endDate, function: { date in resultSetFuture.append(queue.append(self.loadFromCSV(req, date: date, updateInfo: updateInfo, baseAssetId: baseAssetId, returnDate: returnDate))) })
                
            _ = resultSetFuture.flatten(on: req.eventLoop).map({ baseAssetOpenInterest in
                print("ok, it's all received (or not) and it's a time for db update")
                
                var oiResult = [BaseAssetOpenInterest]()
                
                for oiPerDay in baseAssetOpenInterest {
                    if oiPerDay.count > 0 {
                        _ = oiPerDay.map { oi in
                            oiResult.append(oi)
                        }
                    }
                }
                
                _ = updateInfo.finishLongOperation(req).map({
                    promise.succeed(oiResult)
                })
            })
        })
        
        return promise.futureResult
    }
    
    func loadFromCSV(_ req: Request, date: Date, updateInfo: UpdateInfo, baseAssetId: UUID, returnDate: Date? = nil) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        let dateString = DateHelper.getDateString(date, format: "yyyyMMdd")
        let promise = req.eventLoop.makePromise(of: [BaseAssetOpenInterest].self)
        
        req.client.get(URI(string: "https://www.moex.com/ru/derivatives/open-positions-csv.aspx?d=\(dateString)&t=2")).map({ response in
            print("data received for \(date), status is \(response.status)")
            if response.status == .ok {
                let string = response.body!.getString(at: 0, length: response.body!.readableBytes, encoding: .utf8)!.replacingOccurrences(of: ",", with: ".")
                let dataset = CSVHelper.getDataset(string)
                var openInterests = [BaseAssetOpenInterest]()
                var returnOpenInterests = [BaseAssetOpenInterest]()
                //let baController = BaseAssetController()
                    
                if dataset.count > 0 {
                    for line in dataset {
                        BaseAssetDictionary.getIdByCode(req, code: line[1]).map({ baseAssetId in
                            if baseAssetId != nil {
                                var openInterest = openInterests.first(where: { return $0.$baseAsset.id == baseAssetId && $0.groupType == BaseAssetOpenInterest.AssetGroupType(rawValue: line[3]) })
                                if openInterest == nil {
                                    openInterest = BaseAssetOpenInterest(baseAssetId: baseAssetId!, date: date, groupType: BaseAssetOpenInterest.AssetGroupType(rawValue: line[3])!)
                                    openInterests.append(openInterest!)
                                }
                                if UInt(Double(line[4]) ?? 0) == 1 {
                                    openInterest!.setIndOpenInterest(longVolume: UInt(Double(line[8]) ?? 0), longNumber: UInt(Double(line[5]) ?? 0), shortVolume: UInt(Double(line[7]) ?? 0), shortNumber: UInt(Double(line[6]) ?? 0))
                                } else {
                                    openInterest!.setComOpenInterest(longVolume: UInt(Double(line[8]) ?? 0), longNumber: UInt(Double(line[5]) ?? 0), shortVolume: UInt(Double(line[7]) ?? 0), shortNumber: UInt(Double(line[6]) ?? 0))
                                }
                            }
                            //print(baController.dictionary.count)
                        }).whenFailure({ error in
                            print("*** Failure: no data in dictionary for \(line[1])")
                            promise.fail(error)
                        })
                    }
                }
                
                _ = openInterests.map { oi in
                    if returnDate != nil && date == returnDate && oi.baseAsset.id == baseAssetId {
                        returnOpenInterests.append(oi)
                    }
                    
                    _ = oi.calcRelativeYear(req).map({ oi in
                        _ = oi.save(on: req.db)
                    })
                }
                
                _ = updateInfo.setUpdateTime(req, date: date).map({
                    _ = returnOpenInterests.map { oi in
                        return oi.calcRelativeYear(req)
                    }.flatten(on: req.eventLoop).map({ returnOpenInterests in
                        promise.succeed(returnOpenInterests)
                    })
                })
            }
        }).whenFailure({ error in
            print("*** Failed request for data \(dateString). Error: \(error)")
            promise.fail(error)
        })
        
        return promise.futureResult
    }
    
    // MARK: database functions
    func loadFromDB(_ req: Request, baseAssetId: UUID, date: Date) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        
        return BaseAssetOpenInterest.query(on: req.db).filter(\.$baseAsset.$id == baseAssetId).filter(\.$date == date).all()
    }
}
