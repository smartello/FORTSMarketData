import Fluent
import Vapor

class OptionContract {
    func load(_ req: Request, baseAssetId: UUID) -> EventLoopFuture<[OptionContract]> {
        return loadFromDB(req, baseAssetId)
    }
    
    // MARK: database functions
    func loadFromDB(_ req: Request, baseAssetId: UUID) -> EventLoopFuture<[OptionContract]> {
        return OptionContract.query(on: req.db).filter(\.$baseAsset.$id == baseAssetId).all()
    }
}
