//
//  DateFormatter+date.swift
//  ochamochi
//
//

import Foundation

extension DateFormatter {
    func date(fromSwapiString dateString: String) -> Date? {
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        self.timeZone = TimeZone(abbreviation: "UTC")
        self.locale = Locale(identifier: "en_US_POSIX")
        return self.date(from: dateString)
    }
}
