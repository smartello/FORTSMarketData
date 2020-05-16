import Fluent
import Vapor

struct UpdateInfoController {
    static func loadUpdateInfo(db: Database, group: String, object: UUID? = nil) -> EventLoopFuture<UpdateInfo?> {
        
        var query = UpdateInfo.query(on: db).filter(\.$group == group)
        if object != nil {  // waiting for a fix for @OptionalField
            query = query.filter(\.$object == object!)
        }
        
        return query.first()
    }
}
