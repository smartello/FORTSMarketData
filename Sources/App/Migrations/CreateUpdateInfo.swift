import Fluent

struct CreateUpdateInfo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("updateInfo")
            .id()
            .field("group", .string, .required)
            .field("object", .uuid)
            .field("datetime", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("updateInfo").delete()
    }
}
