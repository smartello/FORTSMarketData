import Fluent
import Vapor

class OptionContractController {
    func load(_ req: Request, baseAssetId: UUID) -> EventLoopFuture<[OptionContract]> {
        return UpdateInfoController.loadUpdateInfo(req, group: OptionContract.schema).flatMap({ updateInfo -> EventLoopFuture<[OptionContract]> in
            
            return self.loadFromDB(req, baseAssetId: baseAssetId).flatMap({ dbOptionContracts -> EventLoopFuture<[OptionContract]> in
                let promise = req.eventLoop.makePromise(of: [OptionContract].self)
                
                if updateInfo.isExpired(DateComponents(day: 1)) {
                    self.loadFromAPI(req, baseAssetId: baseAssetId, updateInfo: updateInfo, loadedFromDB: dbOptionContracts)
                        
                        .map({ apiOptionContracts in
                        let newOptionContracts = apiOptionContracts.filter({ apiOptionContract in
                            return dbOptionContracts.first(where: { dbOptionContract in
                                return (dbOptionContract.$baseAsset.id == apiOptionContract.$baseAsset.id) && (dbOptionContract.expirationDate == apiOptionContract.expirationDate)
                            }) != nil
                        })
                        if newOptionContracts.count > 0 {
                            _ = newOptionContracts.map({ newOptionContract -> Void in
                                _ = newOptionContract.save(on: req.db)
                            })
                        }
                        
                        promise.succeed(dbOptionContracts + newOptionContracts)
                    }).whenFailure({ error in
                        promise.succeed(dbOptionContracts)
                    })
                } else {
                    promise.succeed(dbOptionContracts)
                }
                
                return promise.futureResult
            })
        })
    }
    
    
    func loadFromAPI(_ req: Request, baseAssetId: UUID, updateInfo: UpdateInfo? = nil, loadedFromDB: [OptionContract]? = []) -> EventLoopFuture<[OptionContract]> {
        // external model definition
        let promise = req.eventLoop.makePromise(of: [OptionContract].self)

        _ = req.client.get("https://iss.moex.com/iss/engines/futures/markets/options/boards/ROPD/securities.json?iss.meta=off&iss.only=securities").flatMapThrowing({ response in
                return try! response.content.decode(CSVHelper.SecurityData.self)
            }).map({ securityData in
                
                _ = UpdateInfoController.setUpdateTime(req, group: OptionContract.schema, updateInfo: updateInfo)
            })
        
        return promise.futureResult
    }
    
    
    // MARK: database functions
    func loadFromDB(_ req: Request, baseAssetId: UUID) -> EventLoopFuture<[OptionContract]> {
        return OptionContract.query(on: req.db).filter(\.$baseAsset.$id == baseAssetId).filter(\.$expirationDate >= DateHelper.getStartOfDay(Date())).all()
    }
}
