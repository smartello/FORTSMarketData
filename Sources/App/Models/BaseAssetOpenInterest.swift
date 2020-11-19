import Fluent
import SQLKit
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
    var comLongVolume: Int
    
    @Field(key: "comLongNumber")
    var comLongNumber: Int
    
    @Field(key: "comShortVolume")
    var comShortVolume: Int
    
    @Field(key: "comShortNumber")
    var comShortNumber: Int
    
    @Field(key: "indLongVolume")
    var indLongVolume: Int
    
    @Field(key: "indLongNumber")
    var indLongNumber: Int
    
    @Field(key: "indShortVolume")
    var indShortVolume: Int
    
    @Field(key: "indShortNumber")
    var indShortNumber: Int
    
    @Field(key: "indVolumeInLong")
    var indVolumeInLong: Float

    @Field(key: "comVolumeInLong")
    var comVolumeInLong: Float
    
    @Field(key: "indVolumeInLongRelativeYear")
    var indVolumeInLongRelativeYear: Float

    @Field(key: "comVolumeInLongRelativeYear")
    var comVolumeInLongRelativeYear: Float

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
        self.indVolumeInLong = 0.0
        self.comVolumeInLong = 0.0
        self.indVolumeInLongRelativeYear = 0.0
        self.comVolumeInLongRelativeYear = 0.0
    }
    
    func setComOpenInterest(longVolume: Int, longNumber: Int, shortVolume: Int, shortNumber: Int) {
        self.comLongVolume = longVolume
        self.comLongNumber = longNumber
        self.comShortVolume = shortVolume
        self.comShortNumber = shortNumber
        
        self.comVolumeInLong = (self.comLongVolume == 0 && self.comShortVolume == 0) ? 0.0 : Float(self.comLongVolume) / Float(comLongVolume + comShortVolume)
    }
    
    func setIndOpenInterest(longVolume: Int, longNumber: Int, shortVolume: Int, shortNumber: Int) {
        self.indLongVolume = longVolume
        self.indLongNumber = longNumber
        self.indShortVolume = shortVolume
        self.indShortNumber = shortNumber
        
        self.indVolumeInLong = (self.indLongVolume == 0 && self.indShortVolume == 0) ? 0.0 : Float(self.indLongVolume) / Float(indLongVolume + indShortVolume)
    }
    
    func calcRelativeYear(_ req: Request) -> EventLoopFuture<BaseAssetOpenInterest> {
        let promise = req.eventLoop.makePromise(of: BaseAssetOpenInterest.self)
        
        if self.indVolumeInLongRelativeYear == 0.0 || self.comVolumeInLongRelativeYear == 0.0 {
            let db: SQLDatabase = req.db as! SQLDatabase
            
            let toDateString = DateHelper.getDateString(Calendar.current.date(byAdding: .day, value: -1, to: self.date)!, format: "yyyy-MM-dd")
            let fromDateString = DateHelper.getDateString(Calendar.current.date(byAdding: .year, value: -1, to: self.date)!, format: "yyyy-MM-dd")
            let filterString = "WHERE \"baseAssetId\" = '\(self.$baseAsset.id)' AND \"date\" >= '\(fromDateString)' AND \"date\" <= '\(toDateString)' AND \"groupType\" = '\(self.groupType.rawValue)'"
            
            db.raw("SELECT MAX(\"indVolumeInLong\") AS maxInd, MIN(\"indVolumeInLong\") as minInd, MAX(\"comVolumeInLong\") as maxCom, MIN(\"comVolumeInLong\") as minCom FROM \"\(BaseAssetOpenInterest.schema)\" \(filterString)").first().map({ resultLine in
                if resultLine != nil {
                    let maxInd = (try? resultLine!.decode(column: resultLine!.allColumns[0], as:  Float.self)) ?? 0.0
                    let minInd = (try? resultLine!.decode(column: resultLine!.allColumns[1], as: Float.self)) ?? 0.0
                    let maxCom = (try? resultLine!.decode(column: resultLine!.allColumns[2], as: Float.self)) ?? 0.0
                    let minCom = (try? resultLine!.decode(column: resultLine!.allColumns[3], as: Float.self)) ?? 0.0
                    
                    if self.indVolumeInLong > maxInd {
                        self.indVolumeInLongRelativeYear = 1.0
                    } else if self.indVolumeInLong < minInd {
                        self.indVolumeInLongRelativeYear = 0.0
                    } else {
                        let indRange = maxInd - minInd
                        self.indVolumeInLongRelativeYear = indRange == 0 ? self.indVolumeInLong : (self.indVolumeInLong - minInd)/indRange
                    }
                    
                    if self.comVolumeInLong > maxCom {
                        self.comVolumeInLongRelativeYear = 1.0
                    } else if self.comVolumeInLong < minCom {
                        self.comVolumeInLongRelativeYear = 0.0
                    } else {
                        let comRange = maxCom - minCom
                        self.comVolumeInLongRelativeYear = comRange == 0 ? self.comVolumeInLong : (self.comVolumeInLong - minCom)/comRange
                    }
                }
                
                promise.succeed(self)
            }).whenFailure({ error in
                promise.succeed(self)
            })
        } else {
            promise.succeed(self)
        }
        
        return promise.futureResult
    }
}
