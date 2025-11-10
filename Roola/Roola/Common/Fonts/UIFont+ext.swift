//
//  UIFont+ext.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI
import UIKit

extension UIFont {
    // ------------------------------------------------------------
    // 1. Helvetica-Neue with the correct weight
    // ------------------------------------------------------------
    static func helveticaNeue(
        forTextStyle style: UIFont.TextStyle,
        weight: UIFont.Weight = .regular
    ) -> UIFont {
        let pointSize = UIFont.preferredFont(forTextStyle: style).pointSize
        
        let fontName: String = {
            switch weight {
            case .regular: return "HelveticaNeue"
            case .medium:  return "HelveticaNeue-Medium"
            case .bold:    return "HelveticaNeue-Bold"
            default:       return "HelveticaNeue"
            }
        }()
        
        guard let customFont = UIFont(name: fontName, size: pointSize) else {
            assertionFailure("Failed to load custom font: \(fontName). Check .ttf / Info.plist.")
            return UIFont.preferredFont(forTextStyle: style)
        }
        
        return UIFontMetrics(forTextStyle: style).scaledFont(for: customFont)
    }
    
    // ------------------------------------------------------------
    // 2. Convert a UIFont → SwiftUI Font (Dynamic Type aware)
    // ------------------------------------------------------------
    func toFont() -> Font {
        Font(self as CTFont)               // UIKit → CoreText → SwiftUI
    }
}
