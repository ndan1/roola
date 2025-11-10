//
//  Font+ext.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 10/11/25.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Font Extension (Your Design System)
extension Font {
    
    // MARK: Headings
    static var heading32Medium: Font {
        .custom("HelveticaNeue-Medium", size: 32, relativeTo: .largeTitle)
    }
    
    static var heading_32Bold: Font {
        .custom("HelveticaNeue-Bold", size: 32, relativeTo: .largeTitle)
    }
    
    static var heading24Medium: Font {
        .custom("HelveticaNeue-Medium", size: 24, relativeTo: .largeTitle)
    }
    
    // MARK: Titles
    static var title1_22Medium: Font {
        .custom("HelveticaNeue-Medium", size: 22, relativeTo: .title2)
    }
    
    static var title2_20Medium: Font {
        .custom("HelveticaNeue-Medium", size: 20, relativeTo: .title3)
    }
    
    static var title3_16Medium: Font {
        .custom("HelveticaNeue-Medium", size: 16, relativeTo: .headline)
    }
    
    // MARK: Button
    static var button16Bold: Font {
        .custom("HelveticaNeue-Bold", size: 16, relativeTo: .headline)
    }
    
    // MARK: Body
    static var body18Medium: Font {
        .custom("HelveticaNeue-Medium", size: 18, relativeTo: .body)
    }
    
    static var body16Regular: Font {
        .custom("HelveticaNeue", size: 16, relativeTo: .body)
    }
    
    static var body15Regular: Font {
        .custom("HelveticaNeue", size: 15, relativeTo: .callout)
    }
    
    // MARK: Caption
    static var caption14Italic: Font {
        // Create base descriptor
        let baseDescriptor = UIFontDescriptor()
            .withFamily("Helvetica Neue")
            .withSymbolicTraits(.traitItalic)
        
        // Safely unwrap
        guard let italicDescriptor = baseDescriptor else {
            // Fallback: use system italic
            return Font.system(size: 14).italic()
        }
        
        let italicFont = UIFont(descriptor: italicDescriptor, size: 14)
        return Font(italicFont as CTFont)
    }
}
