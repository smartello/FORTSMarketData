import Fluent

struct CreateOptionContract: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("optionContract")
            .id()
            .field("baseAssetId", .uuid, .references("baseAsset", "id"))
            .field("expirationDate", .date)
            .field("name", .string)
            .unique(on: "baseAssetId", "expirationDate")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("optionContract").delete()
    }
}
