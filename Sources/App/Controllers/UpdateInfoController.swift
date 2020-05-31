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
    
    static func createUpdateInfo(_ req: Request, group: String, object: UUID? = nil, date: Date) {
        if object == nil { // unique constraint doesn't work because of nil, ensure there's no entry
            _ = loadUpdateInfo(db: req.db, group: group).map({ updateInfo in
                if updateInfo == nil {
                    _ = UpdateInfo(group: group, datetime: date).save(on: req.db)
                } else {
                    updateInfo!.setUpdateTime(req, date: date)
                }
            })
        } else {
            _ = UpdateInfo(group: group, object: object, datetime: date).save(on: req.db)
        }
    }
}
