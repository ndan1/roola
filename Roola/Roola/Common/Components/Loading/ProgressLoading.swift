//
//  ProgressLoading.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 11/11/25.
//

import SwiftUI

struct ProgressLoading: View {
    @State private var progress: Double = 0.0
    
    let title: String
    let subtitle: String
    let duration: TimeInterval
    
    var onFinish: (() -> Void)?
    
    var body: some View {
        ZStack {
            Image("GradientLoading")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.title1_22Medium)
                    .foregroundColor(AppColors.primaryBlack)
                
                Text(subtitle)
                    .font(.body15Regular)
                    .foregroundColor(AppColors.primaryBlack)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)
                        
                        // Progress fill
                        Capsule()
                            .fill(AppColors.primaryPurple)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.linear(duration: 0.1), value: progress)
                    }
                }
                .frame(height: 8)
                .background(
                    Capsule()
                        .fill(AppColors.primaryWhite))
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .task {
            await runProgress()
        }
    }
    
    private func runProgress() async {
        let steps = 100
        let interval = duration / Double(steps)
        
        for _ in 0..<steps {
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            await MainActor.run {
                progress += 1.0 / Double(steps)
            }
        }
        
        // Complete
        await MainActor.run {
            progress = 1.0
            onFinish?()
        }
    }
}

#Preview {
    ProgressLoading(title: "Hang Tight", subtitle: "We're tailoring this for you.", duration: 5.0)
}

//.task {
//    progress = 0.0
//    // Example: simulate API with progress
//    for await update in apiService.generateOutfit(userMeasurements: data) {
//        await MainActor.run {
//            progress = update.progress // 0.0 to 1.0
//        }
//    }
//}
