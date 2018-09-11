//
//  UIColorExtenstions.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import UIKit

extension UIColor {
    func isEqualTo(_ color: UIColor) -> Bool {
        var originalRed: CGFloat = 0
        var originalGreen: CGFloat = 0
        var originalBlue: CGFloat = 0
        var originalAlpha: CGFloat = 0
        getRed(&originalRed, green:&originalGreen, blue:&originalBlue, alpha:&originalAlpha)

        var colorRed: CGFloat = 0
        var colorGreen: CGFloat = 0
        var colorBlue: CGFloat = 0
        var colorAlpha: CGFloat = 0
        color.getRed(&colorRed, green:&colorGreen, blue:&colorBlue, alpha:&colorAlpha)

        return originalRed == colorRed && originalGreen == colorGreen && originalBlue == colorBlue && originalAlpha == colorAlpha
    }
}
