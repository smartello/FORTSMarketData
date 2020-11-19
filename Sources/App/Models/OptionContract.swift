import Fluent
import Vapor

final class OptionContract: Model, Content {
    static let schema = "optionContract"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "baseAssetId")
    var baseAsset: BaseAsset
    
    @Field(key: "expirationDate")
    var expirationDate: Date
    
    @Field(key: "name")
    var name: String
    
    
    init() { }
    
    init(id: UUID? = nil, baseAssetId: UUID, expirationDate: Date, name: String) {
        self.id = id
        self.$baseAsset.id = baseAssetId
        self.expirationDate = expirationDate
        self.name = name
    }
}
