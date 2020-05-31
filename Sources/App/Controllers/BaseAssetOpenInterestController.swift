import Fluent
import Vapor

struct BaseAssetOpenInterestController {
    let depth: Int = 365 //want to get the data for the whole year
    
    func load(_ req: Request, baseAssetId: UUID, date: Date) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        return UpdateInfoController.loadUpdateInfo(db: req.db, group: BaseAssetOpenInterest.schema).flatMap({
            updateInfo -> EventLoopFuture<[BaseAssetOpenInterest]> in
            
            if (updateInfo == nil || !updateInfo!.isToday()) {
                let startDate = updateInfo == nil ? Calendar.current.date(byAdding: DateComponents(day: -1 * self.depth), to: Date())! : updateInfo!.getDate()
                return self.loadFromCSV(req, endDate: date, startDate: startDate, baseAssetId: baseAssetId, returnDate: date, updateInfo: updateInfo)
            } else {
                return self.loadFromDB(req, baseAssetId: baseAssetId, date: date)
            }
        })
    }
    
    // @MARK: load from CSV file
    func loadFromCSV(_ req: Request, endDate: Date, startDate: Date, baseAssetId: UUID, returnDate: Date? = nil, updateInfo: UpdateInfo? = nil) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        let promise = req.eventLoop.makePromise(of: [BaseAssetOpenInterest].self)
        var resultSetFuture = [EventLoopFuture<[BaseAssetOpenInterest]>]()
        
        DateHelper.iterateMidnights(startDate: startDate, endDate: endDate, function: { date in resultSetFuture.append(loadFromCSV(req, date: date)) })
            
        _ = resultSetFuture.flatten(on: req.eventLoop).map({ baseAssetOpenInterest in
            var oiResult = [BaseAssetOpenInterest]()
            
            for oiPerDay in baseAssetOpenInterest {
                if oiPerDay.count > 0 {
                    for oi in oiPerDay {
                        if oi.date == returnDate && oi.baseAsset.id == baseAssetId {
                            oiResult.append(oi)
                        }
                        
                        _ = oi.save(on: req.db)
                    }
                }
            }
            
            promise.succeed(oiResult)
            if updateInfo == nil {
                UpdateInfoController.createUpdateInfo(req, group: BaseAssetOpenInterest.schema, date: Date())
            } else {
                updateInfo?.setUpdateTime(req, date: Date())
            }
        })
        
        return promise.futureResult
    }
    
    func loadFromCSV(_ req: Request, date: Date) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        let dateString = DateHelper.getDateString(date)
        let promise = req.eventLoop.makePromise(of: [BaseAssetOpenInterest].self)
        
        req.client.get(URI(string: "https://www.moex.com/ru/derivatives/open-positions-csv.aspx?d=\(dateString)&t=2")).map({ response in
            print("data received for \(date), status is \(response.status)")
            if response.status == .ok {
                let string = response.body!.getString(at: 0, length: response.body!.readableBytes, encoding: .utf8)!.replacingOccurrences(of: ",", with: ".")
                let dataset = CSVHelper.getDataset(string)
                var openInterests = [BaseAssetOpenInterest]()
                //let baController = BaseAssetController()
                    
                if dataset.count > 0 {
                    for line in dataset {
                        _ = BaseAssetDictionary.getIdByCode(req, code: line[1]).map({ baseAssetId in
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
                        })
                    }
                }
                
                promise.succeed(openInterests)
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
