import Fluent

struct CreateFutureContract: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("futureContract")
            .id()
            .field("baseAssetId", .uuid, .references("baseAsset", "id"))
            .field("expirationDate", .date)
            .field("secid", .custom("VARCHAR(4)"))
            .field("latname", .custom("VARCHAR(10)"))
            .unique(on: "secid")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("futureContract").delete()
    }
}
