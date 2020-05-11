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

    init() { }

    init(id: UUID? = nil, group: String, object: UUID? = nil, datetime: Date) {
        self.id = id
        self.group = group
        self.object = object
        self.datetime = datetime
    }
}
