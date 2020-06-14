import Vapor
import Fluent

final class BaseAssetDetailed: Content {
    var baseAsset: BaseAsset
    var openInterestFutures = [BaseAssetOpenInterest]()
    var openInterestOptionsPut = [BaseAssetOpenInterest]()
    var openInterestOptionsCall = [BaseAssetOpenInterest]()
        
    init(_ req: Request, baseAsset: BaseAsset) {
        self.baseAsset = baseAsset
    }
    
    func loadOpenInterest(_ req: Request) -> EventLoopFuture<BaseAssetDetailed> {
        let promise = req.eventLoop.makePromise(of: BaseAssetDetailed.self)
        
        let previousDate = DateHelper.getPreviousDay(Date())
        let previousDateMinusMonth = Calendar.current.date(byAdding: DateComponents(month: -1), to: previousDate)!
        
        let baoiController = BaseAssetOpenInterestController()
        _ = baoiController.load(req, baseAssetId: self.baseAsset.id!, startDate: previousDateMinusMonth, endDate: previousDate).map({ baoi in
            for oi in baoi {
                if oi.groupType == .futures {
                    self.openInterestFutures.append(oi)
                } else if oi.groupType == .option_put {
                    self.openInterestOptionsPut.append(oi)
                } else if oi.groupType == .option_call {
                    self.openInterestOptionsCall.append(oi)
                }
            }
            promise.succeed(self)
        }).whenFailure({ error in
            promise.succeed(self)
        })
        
        return promise.futureResult
    }
}
