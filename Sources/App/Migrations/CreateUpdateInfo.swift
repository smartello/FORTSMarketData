import Fluent

struct CreateUpdateInfo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("UpdateInfo")
            .id()
            .field("datetime", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("UpdateInfo").delete()
    }
}
