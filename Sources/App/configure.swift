import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .whitelist(["http://localhost:3000", "http://labs.kashin.me:3000"]),
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    let error = ErrorMiddleware.default(environment: app.environment)
    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(error)
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "marketdata",
        password: Environment.get("DATABASE_PASSWORD") ?? "marketdata",
        database: Environment.get("DATABASE_NAME") ?? "marketdata"
    ), as: .psql)

    app.migrations.add(CreateUpdateInfo())
    app.migrations.add(CreateBaseAsset())
    do {
        try app.autoMigrate().wait()
    } catch { }
    
    // register routes
    try routes(app)
}
