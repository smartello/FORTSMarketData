import Fluent
import SQLKit
import Vapor

final class BaseAssetOpenInterestPercentiles: Content {
    var indVolumeInLongMean: Float
    var indVolumeInLongTop: Float
    var indVolumeInLongBottom: Float
    var comVolumeInLongMean: Float
    var comVolumeInLongTop: Float
    var comVolumeInLongBottom: Float
    
    init(_ req: Request, topPercent: Float, meanPercent: Float, bottomPercent: Float, keyDate: Date, length: UInt) {
        
        self.indVolumeInLongMean = 0.0
        self.indVolumeInLongTop = 0.0
        self.indVolumeInLongBottom = 0.0
        self.comVolumeInLongMean = 0.0
        self.comVolumeInLongTop = 0.0
        self.comVolumeInLongBottom = 0.0
        
        let toDateString = DateHelper.getDateString(keyDate, format: "yyyy-MM-dd")
        let fromDateString = DateHelper.getDateString(Calendar.current.date(byAdding: .day, value: -1*Int(length), to: keyDate)!, format: "yyyy-MM-dd")
        let filterString = "WHERE \"date\" >= '\(fromDateString)' AND \"date\" <= '\(toDateString)'"
        let queryString = "SELECT \(self.getFieldsForGroup(topPercent: topPercent, meanPercent: meanPercent, bottomPercent: bottomPercent, group: ""))"
        
        
        let db: SQLDatabase = req.db as! SQLDatabase
       // db.raw("SELECT percentile_disc(\(topPercent)) within group (order by \"indLongVolume\"), percentile_disc(\(meanPercent)) within group (order by \"indLongVolume\"), percentile_disc(\(bottomPercent)) within group (order by \"indLongVolume\"), percentile_disc(0.8) within group (order by \"indShortVolume\") FROM \"baseAssetOpenInterest\" \(filter) GROUP BY \"baseAssetId\")
        
//        req.db.withConnection({ conn in
//            conn.
//        })
        //let query: DatabaseQuery
        //query.sql
        //query.
        // SELECT percentile_disc(0.8) within group (order by "indLongVolume"), percentile_disc(0.8) within group (order by "indShortVolume") FROM "baseAssetOpenInterest" GROUP BY "baseAssetId"
    }
    
    func getFieldsForGroup(topPercent: Float, meanPercent: Float, bottomPercent: Float, group: String) -> String {
        return "percentile_disc(\(topPercent)) within group (order by \"\(group)\"), percentile_disc(\(meanPercent)) within group (order by \"\(group)\"), percentile_disc(\(bottomPercent)) within group (order by \"\(group)\")"
    }
}
