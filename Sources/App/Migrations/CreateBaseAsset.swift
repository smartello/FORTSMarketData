import Fluent

struct CreateBaseAsset: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAsset")
            .id()
            .field("code", .custom("VARCHAR(4)"), .required)
            .field("shortcut", .custom("VARCHAR(40)"), .required)
            .field("name", .string)
            .unique(on: "code")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAsset").delete()
    }
}
