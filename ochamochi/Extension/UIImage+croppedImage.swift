//
//  UIImage+croppedImage.swift
//  ochamochi
//
//

import Foundation
import UIKit
import CoreGraphics

extension UIImage {
    func croppedImage(bounds: CGRect) -> UIImage {
        let cgImage = self.cgImage?.cropping(to: bounds)
        return UIImage(cgImage: cgImage!, scale: self.scale, orientation: self.imageOrientation)
    }
}
