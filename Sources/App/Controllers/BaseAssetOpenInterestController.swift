import Fluent
import Vapor

struct BaseAssetOpenInterestController {
    
    // @MARK: load from CSV file
    func loadOpenInterestFromCSV(_ req: Request, date: Date) -> EventLoopFuture<[BaseAssetOpenInterest]> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        let promise = req.eventLoop.makePromise(of: [BaseAssetOpenInterest].self)
        
        _ = req.client.get(URI(string: "https://www.moex.com/ru/derivatives/open-positions-csv.aspx?d=\(dateString)&t=2")).map({ response in
            
            if response.status == .ok {
                let string = response.body!.getString(at: 0, length: response.body!.readableBytes, encoding: .utf8)!.replacingOccurrences(of: ",", with: ".")
                let dataset = CSVHelper.getDataset(string)
                if dataset.count > 0 {
                    var openInterests = [BaseAssetOpenInterest]()
                        
                    for line in dataset {
                        _ = BaseAssetController().getIdByCode(req, code: line[2]).map({ baseAssetId in
                            if baseAssetId != nil {
                                var openInterest = openInterests.first(where: { return $0.baseAsset.id == baseAssetId && $0.groupType == BaseAssetOpenInterest.AssetGroupType(rawValue: line[3]) })
                                if openInterest == nil {
                                    openInterest = BaseAssetOpenInterest(baseAssetId: baseAssetId!, date: date, groupType: BaseAssetOpenInterest.AssetGroupType(rawValue: line[3])!)
                                    openInterests.append(openInterest!)
                                }
                                if line[4] == "1" {
                                    openInterest!.setIndOpenInterest(longVolume: UInt(line[8])!, longNumber: UInt(line[5])!, shortVolume: UInt(line[7])!, shortNumber: UInt(line[6])!)
                                } else {
                                    openInterest!.setComOpenInterest(longVolume: UInt(line[8])!, longNumber: UInt(line[5])!, shortVolume: UInt(line[7])!, shortNumber: UInt(line[6])!)
                                }
                            }
                        })
                    }
                    
                    promise.succeed(openInterests)
                }
            }
        })
        
        return promise.futureResult
    }
}
