import Fluent
import Vapor

final class FutureContract: Model, Content {
    static let schema = "futureContract"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "baseAssetId")
    var baseAsset: BaseAsset
    
    @Field(key: "expirationDate")
    var expirationDate: Date
    
    @Field(key: "secid")
    var secid: String
    
    @Field(key: "latname")
    var latname: String
    
    
    init() { }
    
    init(id: UUID? = nil, baseAssetId: UUID, expirationDate: Date, secid: String, latname: String) {
        self.id = id
        self.$baseAsset.id = baseAssetId
        self.expirationDate = expirationDate
        self.secid = secid
        self.latname = latname
    }
}
