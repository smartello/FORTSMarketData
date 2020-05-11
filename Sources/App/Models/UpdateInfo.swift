import Fluent
import Vapor

final class UpdateInfo: Model {
    typealias IDValue = String
    
    static let schema = "UpdateInfo"
    
    @ID(key: "id")
    var id: String?
    
    @Field(key: "datetime")
    var datetime: Date

    init() { }

    init(id: String? = "", datetime: Date) {
        self.id = id
        self.datetime = datetime
    }
}
