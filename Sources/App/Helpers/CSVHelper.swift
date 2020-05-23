struct CSVHelper {
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
