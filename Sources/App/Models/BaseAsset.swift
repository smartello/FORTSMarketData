import Fluent
import Vapor

final class BaseAsset: Model, Content {
    typealias IDValue = String
    
    static let schema = "baseAsset"
    
    @ID(custom: "id")
    var id: String?
    
    @Field(key: "shortcut")
    var shortcut: String
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: String, shortcut: String, name: String) {
        self.id = id
        self.shortcut = shortcut
        self.name = name
    }
}
