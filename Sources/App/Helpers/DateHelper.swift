import Vapor

struct DateHelper {
    static func getDateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: date)
    }
    
    static func getStartOfDay(_ date: Date) -> Date {
        return Calendar.current.startOfDay(for: date).advanced(by: TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: date)))
    }
    
    static func iterateMidnights(startDate: Date, endDate: Date, function: (_: Date) -> Void ) {
        let newStartDate = DateHelper.getStartOfDay(startDate)
        
        // Finding matching dates at midnight - adjust as needed
        let components = DateComponents(hour: 0, minute: 0, second: 0) // midnight
        function(newStartDate)
        Calendar.current.enumerateDates(startingAfter: newStartDate, matching: components, matchingPolicy: .nextTime) { (date, strict, stop) in
            if let date = date {
                if date <= endDate {
                    let startOfDay = getStartOfDay(date)
                    function(startOfDay)
                    //resultSetFuture.append(loadFromCSV(req, date: date))
                } else {
                    stop = true
                }
            }
        }
    }
}
