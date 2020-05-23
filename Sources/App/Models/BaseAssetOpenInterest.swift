import Fluent
import Vapor

final class BaseAssetOpenInterest: Model, Content {
    enum AssetGroupType: String, Codable {
        case futures = "F"
        case option_call = "C"
        case option_put = "P"
    }
    
    static let schema = "baseAssetOpenInterest"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "baseAssetId")
    var baseAsset: BaseAsset
    
    @Field(key: "date")
    var date: Date

    @Field(key: "groupType")
    var groupType: AssetGroupType
    
    @Field(key: "comLongVolume")
    var comLongVolume: UInt
    
    @Field(key: "comLongNumber")
    var comLongNumber: UInt
    
    @Field(key: "comShortVolume")
    var comShortVolume: UInt
    
    @Field(key: "comShortNumber")
    var comShortNumber: UInt
    
    @Field(key: "indLongVolume")
    var indLongVolume: UInt
    
    @Field(key: "indLongNumber")
    var indLongNumber: UInt
    
    @Field(key: "indShortVolume")
    var indShortVolume: UInt
    
    @Field(key: "indShortNumber")
    var indShortNumber: UInt
    
    init() {}
    
    init(id: UUID? = nil, baseAssetId: UUID, date: Date, groupType: AssetGroupType) {
        self.id = id
        self.$baseAsset.id = baseAssetId
        self.date = date
        self.groupType = groupType
        
        self.comLongVolume = 0
        self.comLongNumber = 0
        self.comShortVolume = 0
        self.comShortNumber = 0
        self.indLongVolume = 0
        self.indLongNumber = 0
        self.indShortVolume = 0
        self.indShortNumber = 0
    }
    
    func setComOpenInterest(longVolume: UInt, longNumber: UInt, shortVolume: UInt, shortNumber: UInt) {
        self.comLongVolume = longVolume
        self.comLongNumber = longNumber
        self.comShortVolume = shortVolume
        self.comShortNumber = shortNumber
    }
    
    func setIndOpenInterest(longVolume: UInt, longNumber: UInt, shortVolume: UInt, shortNumber: UInt) {
        self.indLongVolume = longVolume
        self.indLongNumber = longNumber
        self.indShortVolume = shortVolume
        self.indShortNumber = shortNumber
    }
}
