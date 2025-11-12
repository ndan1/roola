//
//  GuideStepView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct GuideStepView: View {
    let number: String
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(number).")
                    .font(.title3_16Medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3_16Medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    GuideStepView(number: "4", title: "test")
}
