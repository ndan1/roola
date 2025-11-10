//
//  YourMeasurementView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 10/11/25.
//

import SwiftUI


struct YourMeasurementView: View {
    @State private var topValue: Int? = 90
    @State private var midValue: Int? = 60
    @State private var botValue: Int? = 30
    var body: some View {
        ZStack{
            FirstGradientBackground()
            VStack(spacing:0){
                TopMeasurementRow(label: "Chest", value: $topValue)
            }
            .padding(.horizontal, 20)
        }
    }
}


#Preview {
    YourMeasurementView()
}

