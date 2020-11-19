struct CSVHelper {
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

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .double(let x):
                try container.encode(x)
            case .string(let x):
                try container.encode(x)
            case .null:
                try container.encodeNil()
            }
        }
        
        var stringValue : String {
            guard case let .string(value) = self else { return "" }
            return value
        }
    }
    
    
    static func getDataset(_ string: String) -> [[String]] {
        var dataset = [[String]]()
        
        var rows = string.components(separatedBy: "\n")
        if rows.count > 0 {
            rows.remove(at: 0)
            for row in rows {
                let columns = row.components(separatedBy: ";")
                if columns.count > 1 {
                    dataset.append(columns)
                }
            }
        }
        
        return dataset
    }
}
