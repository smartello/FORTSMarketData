import Fluent
import Vapor

final class UpdateInfo: Model {
    static let schema = "updateInfo"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "group")
    var group: String
    
    @OptionalField(key: "object")
    var object: UUID?
    
    @Field(key: "datetime")
    var datetime: Date
    
    @Field(key: "longOperationStart")
    var longOperationStart: Date?

    init() { }

    init(id: UUID? = nil, group: String, object: UUID? = nil, datetime: Date, longOperationStart: Date? = nil) {
        self.id = id
        self.group = group
        self.object = object
        self.datetime = datetime
        self.longOperationStart = longOperationStart
    }
    
    func isExpired(_ dc: DateComponents) -> Bool {
        return Calendar.current.date(byAdding: dc, to: self.datetime)! < Date()
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self.datetime)
    }
    
    func getDate() -> Date {
        return self.datetime
    }
    
    func startLongOperation(_ req: Request) -> EventLoopFuture<Void> {
        self.longOperationStart = Date()
        return self.update(on: req.db)
    }
    
    func setUpdateTime(_ req: Request, date: Date) -> EventLoopFuture<Void> {
        self.datetime = date
        self.longOperationStart = nil
        return self.update(on: req.db)
    }
}
