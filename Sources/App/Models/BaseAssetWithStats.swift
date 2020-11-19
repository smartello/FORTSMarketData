import Vapor
import Fluent

final class BaseAssetWithStats: Content {
    let baseAsset: BaseAsset
    
    var openInterestF: Int = 0
    var indVolumeInLongRelativeYearF: Float = 0.0
    var comVolumeInLongRelativeYearF: Float = 0.0
    
    init(_ baseAsset: BaseAsset) {
        self.baseAsset = baseAsset
    }
}
