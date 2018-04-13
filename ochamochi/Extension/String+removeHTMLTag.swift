//
//  String+removeHTMLTag.swift
//  ochamochi
//
//

import Foundation

extension String {
    func removeHTMLTag() -> String {
        return self.replacingOccurrences(of: "<br>", with: "\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "<br />", with: "\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "</p><p>", with: "\n\n", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&lt;", with: "<", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&gt;", with: ">", options: .regularExpression, range: nil)
    }
}
