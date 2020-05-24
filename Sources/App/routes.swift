import Vapor

func routes(_ app: Application) throws {
    let baseAssetController = BaseAssetController()
    app.get("", use: baseAssetController.index)
    app.get(":baseAssetCode", use: baseAssetController.details)
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
