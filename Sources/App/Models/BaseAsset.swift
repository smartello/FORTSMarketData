import Fluent
import Vapor

final class BaseAsset: Model, Content {
    static let schema = "baseAsset"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "shortcut")
    var shortcut: String
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: UUID? = nil, code: String, shortcut: String, name: String) {
        self.id = id
        self.code = code
        self.shortcut = shortcut
        self.name = name
    }
}
