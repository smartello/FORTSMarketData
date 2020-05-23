import Fluent

struct CreateBaseAssetOpenInterest: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAssetOpenInterest")
            .id()
            .field("baseAssetId", .uuid, .references("baseAsset", "id"))
            .field("date", .date)
            .field("groupType", .custom("CHARACTER"))
            .field("comLongVolume", .uint)
            .field("comLongNumber", .uint)
            .field("comShortVolume", .uint)
            .field("comShortNumber", .uint)
            .field("indLongVolume", .uint)
            .field("indLongNumber", .uint)
            .field("indShortVolume", .uint)
            .field("indShortNumber", .uint)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAssetOpenInterest").delete()
    }
}
