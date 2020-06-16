import Vapor
import Fluent
import SQLKit

final class BaseAssetDetailed: Content {
    struct Percentiles: Content {
        var comTop: Float = 0
        var comMean: Float = 0
        var comBottom: Float = 0
        var indTop: Float = 0
        var indMean: Float = 0
        var indBottom: Float = 0
    }
    
    struct OpenInterestWithPercentiles: Content {
        var percentiles: Percentiles = Percentiles()
        var openInterest: [BaseAssetOpenInterest] = [BaseAssetOpenInterest]()
    }
    
    var baseAsset: BaseAsset
    var futures = OpenInterestWithPercentiles()
    var optionsPut = OpenInterestWithPercentiles()
    var optionsCall = OpenInterestWithPercentiles()
        
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
                    self.futures.openInterest.append(oi)
                } else if oi.groupType == .option_put {
                    self.optionsPut.openInterest.append(oi)
                } else if oi.groupType == .option_call {
                    self.optionsCall.openInterest.append(oi)
                }
            }
            promise.succeed(self)
        }).whenFailure({ error in
            promise.succeed(self)
        })
        
        return promise.futureResult
    }
    
    func loadPercentiles(_ req: Request, topPercentile: Float, meanPercentile: Float, bottomPercentile: Float, keyDate: Date, length: UInt) -> EventLoopFuture<BaseAssetDetailed> {
        let promise = req.eventLoop.makePromise(of: BaseAssetDetailed.self)
        
        let toDateString = DateHelper.getDateString(keyDate, format: "yyyy-MM-dd")
        let fromDateString = DateHelper.getDateString(Calendar.current.date(byAdding: .day, value: -1*Int(length), to: keyDate)!, format: "yyyy-MM-dd")
        let filterString = "WHERE \"baseAssetId\" = '\(self.baseAsset.id!)' AND \"date\" >= '\(fromDateString)' AND \"date\" <= '\(toDateString)'"
        let fieldsString = "percentile_disc(\(topPercentile)) within group (order by \"comVolumeInLongRelativeYear\") as comTop, percentile_disc(\(meanPercentile)) within group (order by \"comVolumeInLongRelativeYear\") as comMean, percentile_disc(\(bottomPercentile)) within group (order by \"comVolumeInLongRelativeYear\") as comBottom, percentile_disc(\(topPercentile)) within group (order by \"indVolumeInLongRelativeYear\") as indTop, percentile_disc(\(meanPercentile)) within group (order by \"indVolumeInLongRelativeYear\") as indMean, percentile_disc(\(bottomPercentile)) within group (order by \"indVolumeInLongRelativeYear\") as indBottom"
        
        let queryString = "SELECT \"groupType\", \(fieldsString) FROM \"baseAssetOpenInterest\" \(filterString) GROUP BY \"groupType\""
        
        let db: SQLDatabase = req.db as! SQLDatabase
        db.raw(SQLQueryString(queryString)).all().map({ results in
            _ = results.map { res in
                let groupType: String = (try? res.decode(column: res.allColumns[0], as:  String.self)) ?? ""
                let comTop = (try? res.decode(column: res.allColumns[1], as:  Float.self)) ?? 0.0
                let comMean = (try? res.decode(column: res.allColumns[2], as:  Float.self)) ?? 0.0
                let comBottom = (try? res.decode(column: res.allColumns[3], as:  Float.self)) ?? 0.0
                let indTop = (try? res.decode(column: res.allColumns[4], as:  Float.self)) ?? 0.0
                let indMean = (try? res.decode(column: res.allColumns[5], as:  Float.self)) ?? 0.0
                let indBottom = (try? res.decode(column: res.allColumns[6], as:  Float.self)) ?? 0.0
                
                switch groupType {
                case BaseAssetOpenInterest.AssetGroupType.futures.rawValue:
                    self.futures.percentiles = Percentiles(comTop: comTop, comMean: comMean, comBottom: comBottom, indTop: indTop, indMean: indMean, indBottom: indBottom)
                case BaseAssetOpenInterest.AssetGroupType.option_call.rawValue:
                    self.optionsCall.percentiles = Percentiles(comTop: comTop, comMean: comMean, comBottom: comBottom, indTop: indTop, indMean: indMean, indBottom: indBottom)
                case BaseAssetOpenInterest.AssetGroupType.option_put.rawValue:
                    self.optionsPut.percentiles = Percentiles(comTop: comTop, comMean: comMean, comBottom: comBottom, indTop: indTop, indMean: indMean, indBottom: indBottom)
                default: break
                }
            }
            
            promise.succeed(self)
        }).whenFailure({ error in
            promise.succeed(self)
        })
        
        return promise.futureResult
    }
}
