import Fluent
import Vapor

class BaseAssetDictionary {
    private static var dictionary = [String:UUID]()
    
    private static func _loadCodeDictionary(_ req: Request) -> EventLoopFuture<[String:UUID]> {
        let promise = req.eventLoop.makePromise(of: [String:UUID].self)
        
        if self.dictionary.count > 0 {
            promise.succeed(dictionary)
        } else {
            var newDictionary = [String:UUID]()
            _ = BaseAssetController().loadFromDB(req).flatMapThrowing({ baseAssets throws in
                for baseAsset in baseAssets {
                    if baseAsset.id != nil {
                        newDictionary[baseAsset.code] = baseAsset.id!
                    }
                }
                if newDictionary.count > 0 {
                    self.dictionary = newDictionary
                    promise.succeed(newDictionary)
                } else {
                    promise.fail(Abort(.notFound, reason: "Asset list is not yet ready, try again later"))
                }
            })
        }
        
        return promise.futureResult
    }
    
    static func getIdByCode(_ req: Request, code: String) -> EventLoopFuture<UUID?> {
        let promise = req.eventLoop.makePromise(of: UUID?.self)
        
        _loadCodeDictionary(req).map({ dictionary in
            let uuid = dictionary[code]
            promise.succeed(uuid)
        }).whenFailure({ error in
            promise.fail(error)
        })
        
        return promise.futureResult
    }
}

struct BaseAssetController {
    // MARK: request processing
    func index(req: Request) throws -> EventLoopFuture<[BaseAssetWithStats]> {
        return UpdateInfoController.loadUpdateInfo(req, group: BaseAsset.schema).flatMap({
            updateInfo -> EventLoopFuture<[BaseAsset]> in
            
            if (updateInfo.isExpired(DateComponents(day: 30))) {
                return self.loadFromAPI(req, updateInfo: updateInfo)
            } else {
                return self.loadFromDB(req)
            }
        }).flatMap({ baseAsset -> EventLoopFuture<[BaseAssetWithStats]> in
            let promise = req.eventLoop.makePromise(of: [BaseAssetWithStats].self)
            
            var baseAssetWithStats = baseAsset.map {
                BaseAssetWithStats($0)
            }
            
            BaseAssetOpenInterest.query(on: req.db).aggregate(.maximum, \.$date, as: Date.self).map({ date in
                BaseAssetOpenInterest.query(on: req.db).filter(\.$groupType, .equal, BaseAssetOpenInterest.AssetGroupType.futures).filter(\.$date, .equal, date).all().map({ openInterest in
                
                    _ = openInterest.map { oi in
                        let currentBA = baseAssetWithStats.first(where: {
                            return $0.baseAsset.id == oi.$baseAsset.id
                        })
                        if currentBA != nil {
                            currentBA!.openInterestF = oi.indLongVolume + oi.indShortVolume + oi.comLongVolume + oi.comShortVolume
                            currentBA!.indVolumeInLongRelativeYearF = oi.indVolumeInLongRelativeYear
                            currentBA!.comVolumeInLongRelativeYearF = oi.comVolumeInLongRelativeYear
                        }
                    }
                    
                    baseAssetWithStats.sort(by: { a,b -> Bool in
                        return a.openInterestF > b.openInterestF
                    })
                    
                    promise.succeed(baseAssetWithStats)
                }).whenFailure({ error in
                    promise.succeed(baseAssetWithStats)
                })
            }).whenFailure({ error in
                promise.succeed(baseAssetWithStats)
            })

            return promise.futureResult
        })
    }
    
    func details(req: Request) throws -> EventLoopFuture<BaseAssetDetailed> {
        let promise = req.eventLoop.makePromise(of: BaseAssetDetailed.self)
        let baseAssetCode = req.parameters.get("baseAssetCode")
        
        BaseAssetDictionary.getIdByCode(req, code: baseAssetCode!).map({ baseAssetId in
            if baseAssetId == nil {
                promise.fail(Abort(.notFound, reason: "No info on \(baseAssetCode!)"))
            } else {
                _ = BaseAsset.find(baseAssetId, on: req.db).map({ baseAsset in
                    if baseAsset == nil {
                        promise.fail(Abort(.notFound, reason: "No info on \(baseAssetCode!)"))
                    } else {
                        let baseAssetDetailed = BaseAssetDetailed(req, baseAsset: baseAsset!)
                        baseAssetDetailed.loadOpenInterest(req).and(baseAssetDetailed.loadPercentiles(req, topPercentile: 0.9, meanPercentile: 0.5, bottomPercentile: 0.1, keyDate: Date(), length: 365)).map({ (bad1, bad2) in
                            promise.succeed(baseAssetDetailed)
                        }).whenFailure({ error in
                            promise.succeed(baseAssetDetailed)
                        })
                    }
                })
            }
        }).whenFailure({ error in
            promise.fail(error)
        })
        
        return promise.futureResult
    }
        
    // MARK: external source processing
    // Retrieves all entries available in API and updates the database
    func loadFromAPI(_ req: Request, updateInfo: UpdateInfo? = nil) -> EventLoopFuture<[BaseAsset]> {
        // external model definition
        let promise = req.eventLoop.makePromise(of: [BaseAsset].self)

        _ = req.client.get("https://iss.moex.com/iss/engines/futures/markets/forts/boards/RFUD/securities.json?iss.only=sequrities&iss.meta=off").flatMapThrowing({ response in
                return try! response.content.decode(CSVHelper.SecurityData.self)
            }).map({ securityData in
                var baseAssetAPI = [BaseAsset]()

                _ = self.loadFromDB(req).map({ baseAssetDB in
                    for line in securityData.securities.data {
                        let newBaseAsset = BaseAsset(code: line[12].stringValue, shortcut: line[10].stringValue, name: "")
                        if !baseAssetAPI.contains(where: { return $0.code == newBaseAsset.code }) && !baseAssetDB.contains(where: { return $0.code == newBaseAsset.code }) {
                            baseAssetAPI.append(newBaseAsset)
                        }
                    }
                    
                    _ = self.loadNames(req, baseAsset: baseAssetAPI).map({ baseAssetAPI in
                        promise.succeed(baseAssetDB + baseAssetAPI)
                        for asset in baseAssetAPI {
                            _ = asset.save(on: req.db)
                        }
                    })
                })
                
                _ = UpdateInfoController.setUpdateTime(req, group: BaseAsset.schema, updateInfo: updateInfo)
            })
        
        return promise.futureResult
    }

    /// Tries to collect readable names for `BaseAsset` from web and fills `name` attribute
    func loadNames(_ req: Request, baseAsset: [BaseAsset]) -> EventLoopFuture<[BaseAsset]> {
        let promise = req.eventLoop.makePromise(of: [BaseAsset].self)
        
        _ = req.client.get("https://www.moex.com/s205/?print=1").map({ response in
            if response.status == .ok {
                let string = response.body!.getString(at: 0, length: response.body!.readableBytes)?.replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "\n|\r|\t|<\\/?span>|<\\/?b>|&shy;", with: "", options: .regularExpression).replacingOccurrences(of: "&ndash;", with: "–").replacingOccurrences(of: "&nbsp;", with: " ")
                let range = NSRange(location: 0, length: string!.count)
                let regex = try! NSRegularExpression(pattern: "<td (align=\"center\"|style=\"text\\-align: center;\")> ?[\\w\\d ]{2} ?<\\/td><td (align=\"center\"|style=\"text\\-align: center;\")>([\\w\\d ]{2,4})<\\/td><td(| style=\"text\\-align: left;\")>([A-Za-zА-Яа-я0-9\\\"\\/\\–\\-\\.\\,\\%() ]*)<\\/td>")
                let matches = regex.matches(in: string!, options: .init(), range: range)
                for match in matches {
                    let codeRange = Range(match.range(at: 3), in: string!)!
                    let code = String(string![codeRange])
                    
                    let itemIndex = baseAsset.firstIndex(where: { return $0.code == code })
                    if itemIndex != nil {
                        let nameRange = Range(match.range(at: 5), in: string!)!
                        baseAsset[itemIndex!].name = String(string![nameRange])
                    }
                }
            }
            
            promise.succeed(baseAsset)
        })
        
        return promise.futureResult
    }
    
    // MARK: database functions
    func loadFromDB(_ req: Request) -> EventLoopFuture<[BaseAsset]> {
        return BaseAsset.query(on: req.db).all()
    }
}
