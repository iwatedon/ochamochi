//
//  NSAttributedString+replaceEmoji.swift
//  ochamochi
//

import Foundation
import UIKit

extension NSAttributedString {
    
    func replaceEmoji(pattern: String, replacement: NSAttributedString) -> NSMutableAttributedString {
        let mutableAttributedString = self.mutableCopy() as! NSMutableAttributedString
        let mutableString = mutableAttributedString.mutableString
        while mutableString.contains(pattern) {
            let range = mutableString.range(of: pattern)
            mutableAttributedString.replaceCharacters(in: range, with: replacement)
        }
        return mutableAttributedString
    }
}
