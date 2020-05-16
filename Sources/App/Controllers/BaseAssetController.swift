import Fluent
import Vapor

struct BaseAssetController {
    // @MARK: main functions
    func index(req: Request) throws -> EventLoopFuture<[BaseAsset]> {
        return UpdateInfoController.loadUpdateInfo(db: req.db, group: "baseAsset").flatMap({
            updateInfo -> EventLoopFuture<[BaseAsset]> in
            
            if (updateInfo == nil) {
                return self.loadFromAPI(req: req)
            } else {
                return self.loadFromDB(req: req)
            }
        })
    }
    
    // @MARK: external source processing
    func loadFromAPI(req: Request) -> EventLoopFuture<[BaseAsset]> {
        let promise = req.eventLoop.makePromise(of: [BaseAsset].self)
        
        let asset = [BaseAsset]()
        promise.succeed(asset)
        
        return promise.futureResult
    }
    
    // @MARK: database functions
    func loadFromDB(req: Request) -> EventLoopFuture<[BaseAsset]> {
        return BaseAsset.query(on: req.db).all()
    }
}
