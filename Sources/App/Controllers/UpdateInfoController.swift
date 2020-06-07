import Fluent
import Vapor

struct UpdateInfoController {
    static func loadUpdateInfo(_ req: Request, group: String, object: UUID? = nil, defaultDate: Date? = nil) -> EventLoopFuture<UpdateInfo> {
        
        var query = UpdateInfo.query(on: req.db).filter(\.$group == group)
        if object != nil {  // waiting for a fix for @OptionalField
            query = query.filter(\.$object == object!)
        }
        
        let promise = req.eventLoop.makePromise(of: UpdateInfo.self)
        
        _ = query.first().map({ updateInfo in
            if updateInfo == nil {
                let datetime = defaultDate == nil ? Date(timeIntervalSince1970: TimeInterval(0)) : defaultDate
                let newUpdateInfo = UpdateInfo(group: group, datetime: datetime!)
                _ = newUpdateInfo.save(on: req.db).map({
                    promise.succeed(newUpdateInfo)
                })
            } else {
                promise.succeed(updateInfo!)
            }
        })
        
        return promise.futureResult
    }
    
    static func createUpdateInfo(_ req: Request, group: String, object: UUID? = nil, date: Date) -> EventLoopFuture<Void> {
        if object == nil { // unique constraint doesn't work because of nil, ensure there's no entry
            return loadUpdateInfo(req, group: group).flatMap({ updateInfo -> EventLoopFuture<Void> in
                return updateInfo.setUpdateTime(req, date: date)
            })
        } else {
            return UpdateInfo(group: group, object: object, datetime: date).save(on: req.db)
        }
    }
    
    static func setUpdateTime(_ req: Request, group: String, updateInfo: UpdateInfo? = nil) -> EventLoopFuture<Void> {
        if updateInfo == nil {
            return createUpdateInfo(req, group: group, date: Date())
        } else {
            return updateInfo!.setUpdateTime(req, date: Date())
        }
    }
}
