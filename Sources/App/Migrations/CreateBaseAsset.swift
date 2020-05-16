import Fluent

struct CreateBaseAsset: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAsset")
            .field("id", .custom("VARCHAR(4)"), .identifier(auto: false))
            .field("shortcut", .custom("VARCHAR(40)"), .required)
            .field("name", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAsset").delete()
    }
}
