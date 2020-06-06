import Fluent

struct CreateUpdateInfo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("updateInfo")
            .id()
            .field("group", .custom("VARCHAR(40)"), .required)
            .field("object", .uuid)
            .field("datetime", .datetime, .required)
            .field("longOperationStart", .datetime)
            .unique(on: "group", "object")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("updateInfo").delete()
    }
}
