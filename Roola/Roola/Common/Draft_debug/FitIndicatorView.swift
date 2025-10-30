//
//  FitIndicatorView.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 18/10/25.
//

import SwiftUI

// MARK: - New Fit Indicator View (Simplified Logic)
struct FitIndicatorView: View {
    let currentFit: FitPreference?
    
    @State private var currentPositionIndex: Int = 2
    private let positions: Int = 5

    init(currentFit: FitPreference?) {
        self.currentFit = currentFit
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let dotDiameter: CGFloat = 14
                let usableWidth = geometry.size.width - dotDiameter
                let segmentWidth = usableWidth / CGFloat(positions - 1)

                ZStack {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(Color(UIColor.systemGray3))
                        .padding(.horizontal, dotDiameter / 2)

                    ForEach(0..<positions, id: \.self) { index in
                        let xPosition = (dotDiameter / 2) + (segmentWidth * CGFloat(index))
                        Circle()
                            .stroke(Color(UIColor.systemGray3), lineWidth: 2)
                            .frame(width: dotDiameter - 2, height: dotDiameter - 2)
                            .position(x: xPosition, y: geometry.size.height / 2)
                    }
                    
                    let animatedDotXPosition = (dotDiameter / 2) + (segmentWidth * CGFloat(currentPositionIndex))
                    
                    Circle()
                        .fill(Color.primary)
                        .frame(width: dotDiameter, height: dotDiameter)
                        .position(x: animatedDotXPosition, y: geometry.size.height / 2)
                        .animation(.easeInOut(duration: 0.4), value: currentPositionIndex)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("Tight")
                Spacer()
                Text("Fit")
                Spacer()
                Text("Loose")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .onChange(of: currentFit) {
            updatePosition()
        }
        .onAppear {
            updatePosition()
        }
    }
    
    private func updatePosition() {
        if let fit = currentFit {
            switch fit {
            case .skinny:
                currentPositionIndex = 0
            case .slim:
                currentPositionIndex = 1
            case .regular:
                currentPositionIndex = 2
            case .loose:
                currentPositionIndex = 3
            }
        } else {
            currentPositionIndex = 2
        }
    }
}
