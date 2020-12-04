import Vapor

func routes(_ app: Application) throws {
    let baseAssetController = BaseAssetController()
    app.get("") { req -> String in
        return "Welcome to MarketData API v.0.0.1. Start with \"/classes\""
    }
    
    app.get("classes", use: baseAssetController.index)
    app.get("classes", ":baseAssetCode", use: baseAssetController.details)
 
    //app.get("admin", "updatetexts", use: )
//    app.get { req in
//        return "It works!"
//    }
//
//    app.get("hello") { req -> String in
//        return "Hello, world!"
//    }
    
    //app.get("date", use: UpdateInfoController.getUpdateTime)
    //let updateInfoController = UpdateInfoController()
    //app.get("date", ":group", use: updateInfoController.getUpdateTime)
}
