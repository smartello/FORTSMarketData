import Vapor
import Fluent

final class BaseAssetDetailed: Content {
    var baseAsset: BaseAsset
    var openInterestFutures: BaseAssetOpenInterest?
    var openInterestOptionsPut: BaseAssetOpenInterest?
    var openInterestOptionsCall: BaseAssetOpenInterest?
    
//    init(req: Request, baseAssetId: UUID) {
//        self.baseAssetId = baseAssetId
//        self.baseAsset = BaseAsset.find(baseAssetId, on: req.db).map({ baseAsset in
//            return baseAsset!
//        })
//    }
    
    init(_ req: Request, baseAsset: BaseAsset) {
        self.baseAsset = baseAsset
    }
    
    func loadOpenInterest(_ req: Request) -> EventLoopFuture<BaseAssetDetailed> {
        let promise = req.eventLoop.makePromise(of: BaseAssetDetailed.self)
        
        let baoiController = BaseAssetOpenInterestController()
        _ = baoiController.load(req, baseAssetId: self.baseAsset.id!, date: Date()).map({ baoi in
            if baoi.count == 0 {
                _ = BaseAssetOpenInterest.query(on: req.db).filter(\.$baseAsset.$id == self.baseAsset.id!).aggregate(.maximum, \.$date, as: Date.self).map({ date in
                    _ = baoiController.load(req, baseAssetId: self.baseAsset.id!, date: date).map({ baoi in
                        
                        for oi in baoi {
                            if oi.groupType == .futures {
                                self.openInterestFutures = oi
                            } else if oi.groupType == .option_put {
                                self.openInterestOptionsPut = oi
                            } else if oi.groupType == .option_call {
                                self.openInterestOptionsCall = oi
                            }
                        }
                        promise.succeed(self)
                    })
                })
            } else {
                for oi in baoi {
                    if oi.groupType == .futures {
                        self.openInterestFutures = oi
                    } else if oi.groupType == .option_put {
                        self.openInterestOptionsPut = oi
                    } else if oi.groupType == .option_call {
                        self.openInterestOptionsCall = oi
                    }
                }
                promise.succeed(self)
            }
        })
        
        return promise.futureResult
    }
}
