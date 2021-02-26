//
//  UIImage+fontAwesomeImage.swift
//  ochamochi
//
//

import Foundation
import UIKit

extension UIImage {
    static func fontAwesomeImage(name: String, textColor: UIColor, size: CGSize, backgroundColor: UIColor = UIColor.clear, borderWidth: CGFloat = 0, borderColor: UIColor = UIColor.clear) -> UIImage {
        
        // Prevent application crash when passing size where width or height is set equal to or less than zero, by clipping width and height to a minimum of 1 pixel.
        var size = size
        if size.width <= 0 { size.width = 1 }
        if size.height <= 0 { size.height = 1 }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = NSTextAlignment.center
        
        let fontSize = min(size.width / 1.28571429, size.height)
        
        // stroke width expects a whole number percentage of the font size
        let strokeWidth: CGFloat = fontSize == 0 ? 0 : (-100 * borderWidth / fontSize)
        
        let attributedString = NSAttributedString(string: name, attributes: [
            NSAttributedStringKey.font : UIFont(name: "FontAwesome5FreeSolid", size: fontSize),
            NSAttributedStringKey.foregroundColor: textColor,
            NSAttributedStringKey.backgroundColor: backgroundColor,
            NSAttributedStringKey.paragraphStyle: paragraph,
            NSAttributedStringKey.strokeWidth: strokeWidth,
            NSAttributedStringKey.strokeColor: borderColor
            ])
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        attributedString.draw(in: CGRect(x: 0, y: (size.height - fontSize) / 2, width: size.width, height: fontSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
