import Fluent
import Vapor

final class BaseAssetOpenInterestStats: Model, Content {
    enum AssetGroupType: String, Codable {
        case futures = "F"
        case option_call = "C"
        case option_put = "P"
    }
    
    static let schema = "baseAssetOpenInterestStats"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "baseAssetId")
    var baseAsset: BaseAsset
    
    @Field(key: "date")
    var date: Date

    @Field(key: "groupType")
    var groupType: AssetGroupType
    
    //var min
    
    
    init() {}
    
    init(id: UUID? = nil, baseAssetId: UUID, date: Date, groupType: AssetGroupType) {
        self.id = id
        self.$baseAsset.id = baseAssetId
        self.date = date
        self.groupType = groupType
    }
}
