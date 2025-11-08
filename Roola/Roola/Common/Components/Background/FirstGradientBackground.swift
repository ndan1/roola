//
//  FirstGradientBackground.swift
//  Roola
//
//  Created by Lin Dan Christiano on 07/11/25.
//

import SwiftUI

struct FirstGradientBackground: View {
    var body: some View {
        ZStack {
            //MARK: PAKE GRADIENT 3 WARNA
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#B6FEFF"),
                    Color(hex: "#F6F4FE"),
                ]),
                center: .center,
                // ubah disini kalo mau gede kecilin yang radial atas
                startRadius: UIScreen.main.bounds.height * 0.5,
                endRadius: UIScreen.main.bounds.height * 0.33
            )
            .edgesIgnoringSafeArea(.all)
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#918FFE"),
                    Color(hex: "#F6F4FE").opacity(0),
                ]),
                center: .center,
                // ubah disini kalo mau gede kecilin yang radial atas
                startRadius: UIScreen.main.bounds.height * 0.55,
                endRadius: UIScreen.main.bounds.height * 0.4
            )
            .edgesIgnoringSafeArea(.all)
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#918FFE"),
                    Color(hex: "#F6F4FE").opacity(0),
                ]),
                center: .center,
                // ubah disini kalo mau gede kecilin yang radial atas
                startRadius: UIScreen.main.bounds.height * 0.55,
                endRadius: UIScreen.main.bounds.height * 0.45
            )
            .edgesIgnoringSafeArea(.all)
            
            //MARK: background tengah
            Color(hex: "#F6F4FE")
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5)
                .padding(.top, UIScreen.main.bounds.height * 0.5)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#6F60E2").opacity(0.4),
                    Color.white.opacity(0)
                ]),
                startPoint: .bottom,
                endPoint: UnitPoint(x: 0.4, y: 0.8)
            )
            .edgesIgnoringSafeArea(.all)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    FirstGradientBackground()
}
