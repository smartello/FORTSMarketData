import Fluent

struct CreateBaseAssetOpenInterest: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAssetOpenInterest")
            .id()
            .field("baseAssetId", .uuid, .references("baseAsset", "id"))
            .field("date", .date)
            .field("groupType", .custom("CHARACTER"))
            .field("comLongVolume", .int)
            .field("comLongNumber", .int)
            .field("comShortVolume", .int)
            .field("comShortNumber", .int)
            .field("indLongVolume", .int)
            .field("indLongNumber", .int)
            .field("indShortVolume", .int)
            .field("indShortNumber", .int)
            .field("indVolumeInLong", .float)
            .field("comVolumeInLong", .float)
            .field("indVolumeInLongRelativeYear", .float)
            .field("comVolumeInLongRelativeYear", .float)
            .unique(on: "baseAssetId", "date", "groupType")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("baseAssetOpenInterest").delete()
    }
}
