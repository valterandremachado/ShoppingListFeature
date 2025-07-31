import Foundation

extension String {
    func toDate(
        format: String = "yyyy-MM-dd'T'HH:mm:ssZ",
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = locale
        formatter.timeZone = timeZone
        return formatter.date(from: self)
    }
}
