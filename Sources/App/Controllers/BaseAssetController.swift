import Fluent
import Vapor

class BaseAssetDictionary {
    private static var dictionary = [String:UUID]()
    
    private static func _loadCodeDictionary(_ req: Request) -> EventLoopFuture<[String:UUID]> {
        let promise = req.eventLoop.makePromise(of: [String:UUID].self)
        
        if self.dictionary.count > 0 {
            promise.succeed(dictionary)
        } else {
            var newDictionary = [String:UUID]()
            _ = BaseAssetController().loadFromDB(req).map({ baseAssets in
                for baseAsset in baseAssets {
                    newDictionary[baseAsset.code] = baseAsset.id!
                    //print(newDictionary[baseAsset.code])
                }
                self.dictionary = newDictionary
                promise.succeed(newDictionary)
            })
        }
        
        return promise.futureResult
    }
    
    static func getIdByCode(_ req: Request, code: String) -> EventLoopFuture<UUID?> {
        let promise = req.eventLoop.makePromise(of: UUID?.self)
        
        _ = _loadCodeDictionary(req).map({ dictionary in
            let uuid = dictionary[code]
            promise.succeed(uuid)
        })
        
        return promise.futureResult
    }
}

struct BaseAssetController {
    // MARK: request processing
    func index(req: Request) throws -> EventLoopFuture<[BaseAsset]> {
        return UpdateInfoController.loadUpdateInfo(db: req.db, group: BaseAsset.schema).flatMap({
            updateInfo -> EventLoopFuture<[BaseAsset]> in
            
            if (updateInfo == nil || updateInfo!.isExpired(DateComponents(day: 30))) {
                return self.loadFromAPI(req)
            } else {
                return self.loadFromDB(req)
            }
        })
    }
    
    func details(req: Request) throws -> EventLoopFuture<BaseAssetDetailed> {
        let promise = req.eventLoop.makePromise(of: BaseAssetDetailed.self)
        let baseAssetCode = req.parameters.get("baseAssetCode")
        
        _ = BaseAssetDictionary.getIdByCode(req, code: baseAssetCode!).map({ baseAssetId in
            BaseAsset.find(baseAssetId, on: req.db).map({ baseAsset in
                if baseAsset == nil {
                    promise.fail(Abort(.notFound, reason: "No info on \(baseAssetCode!)"))
                } else {
                    let baseAssetDetailed = BaseAssetDetailed(req, baseAsset: baseAsset!)
                    _ = baseAssetDetailed.loadOpenInterest(req).map({ bad in
                        promise.succeed(bad)
                    })
                    
                }
            })
        })
        
        return promise.futureResult
    }
        
    // MARK: external source processing
    // Retrieves all entries available in API and updates the database
    func loadFromAPI(_ req: Request) -> EventLoopFuture<[BaseAsset]> {
        // external model definition
        struct SecurityData: Decodable {
            let securities: Securities
        }

        struct Securities: Decodable {
            let columns: [String]
            let data: [[Datum]]
        }
        
        enum Datum: Decodable {
            case double(Double)
            case string(String)
            case null

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let x = try? container.decode(Double.self) {
                    self = .double(x)
                    return
                }
                if let x = try? container.decode(String.self) {
                    self = .string(x)
                    return
                }
                if container.decodeNil() {
                    self = .null
                    return
                }
                throw DecodingError.typeMismatch(Datum.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Datum"))
            }
            
            var stringValue : String {
                guard case let .string(value) = self else { return "" }
                return value
            }
        }
        
        let promise = req.eventLoop.makePromise(of: [BaseAsset].self)

        _ = req.client.get("http://iss.moex.com/iss/engines/futures/markets/forts/boards/RFUD/securities.json?iss.only=sequrities&iss.meta=off").flatMapThrowing({ response in
                return try! response.content.decode(SecurityData.self)
            }).map({ securityData in
                var baseAssetAPI = [BaseAsset]()

                _ = self.loadFromDB(req).map({ baseAssetDB in
                    for line in securityData.securities.data {
                        let newBaseAsset = BaseAsset(code: line[12].stringValue, shortcut: line[10].stringValue, name: "")
                        if !baseAssetAPI.contains(where: { return $0.code == newBaseAsset.code }) && !baseAssetDB.contains(where: { return $0.code == newBaseAsset.code }) {
                            baseAssetAPI.append(newBaseAsset)
                        }
                    }
                    
                    _ = self.loadNames(req, baseAsset: baseAssetAPI).map({ baseAssetAPI in
                        promise.succeed(baseAssetDB + baseAssetAPI)
                        for asset in baseAssetAPI {
                            _ = asset.save(on: req.db)
                        }
                    })
                })
                
                _ = UpdateInfo(group: BaseAsset.schema, datetime: Date()).save(on: req.db)
                
            })
        
        return promise.futureResult
    }

    /// Tries to collect readable names for `BaseAsset` from web and fills `name` attribute
    func loadNames(_ req: Request, baseAsset: [BaseAsset]) -> EventLoopFuture<[BaseAsset]> {
        let promise = req.eventLoop.makePromise(of: [BaseAsset].self)
        
        _ = req.client.get("https://www.moex.com/s205/?print=1").map({ response in
            if response.status == .ok {
                let string = response.body!.getString(at: 0, length: response.body!.readableBytes)?.replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "\n|\r|\t|<\\/?span>|<\\/?b>|&shy;", with: "", options: .regularExpression).replacingOccurrences(of: "&ndash;", with: "–").replacingOccurrences(of: "&nbsp;", with: " ")
                let range = NSRange(location: 0, length: string!.count)
                let regex = try! NSRegularExpression(pattern: "<td (align=\"center\"|style=\"text\\-align: center;\")> ?[\\w\\d ]{2} ?<\\/td><td (align=\"center\"|style=\"text\\-align: center;\")>([\\w\\d ]{2,4})<\\/td><td>([A-Za-zА-Яа-я0-9\\\"\\/\\–\\-\\.\\,\\%() ]*)<\\/td>")
                let matches = regex.matches(in: string!, options: .init(), range: range)
                for match in matches {
                    let codeRange = Range(match.range(at: 3), in: string!)!
                    let code = String(string![codeRange])
                    
                    let itemIndex = baseAsset.firstIndex(where: { return $0.code == code })
                    if itemIndex != nil {
                        let nameRange = Range(match.range(at: 4), in: string!)!
                        baseAsset[itemIndex!].name = String(string![nameRange])
                    }
                }
            }
            
            promise.succeed(baseAsset)
        })
        
        return promise.futureResult
    }
    
    // MARK: database functions
    func loadFromDB(_ req: Request) -> EventLoopFuture<[BaseAsset]> {
        return BaseAsset.query(on: req.db).all()
    }
}
