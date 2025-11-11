//
//  ResultsView.swift
//  Roola
//
//  Created by Lin Dan Christiano on 11/11/25.
//

import SwiftUI

//struct ResultsView: View {
//    @ObservedObject var viewModel: RecommendationViewModel
//    @Binding var showResults: Bool
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    if let recommendations = viewModel.serverResponse?.recommendations {
//                        Text("Size Recommendations")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//                            .padding(.top)
//                        
//                        // Map the 5 fit types to new names
//                        RecommendationCard(
//                            fit: "Tight",
//                            recommendation: recommendations.tight
//                        )
//                        
//                        RecommendationCard(
//                            fit: "Slim",
//                            recommendation: recommendations.slightlyTight
//                        )
//                        
//                        RecommendationCard(
//                            fit: "Standard",
//                            recommendation: recommendations.regular
//                        )
//                        
//                        RecommendationCard(
//                            fit: "Relaxed",
//                            recommendation: recommendations.slightlyLoose
//                        )
//                        
//                        RecommendationCard(
//                            fit: "Loose",
//                            recommendation: recommendations.loose
//                        )
//                        
//                    } else if viewModel.isCallingAPI {
//                        ProgressView("Calculating Recommendations...")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                    } else if let apiError = viewModel.apiError {
//                        Text(apiError)
//                            .foregroundColor(.red)
//                            .padding()
//                    }
//                }
//                .padding(.bottom)
//            }
//            .navigationTitle("Your Results")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        showResults = false
//                    }
//                }
//            }
//        }
//    }
//}

struct ResultsView: View {
    @State private var notAvailableStatus: Bool = true
    @State var sliderValue : Float = 0.0
    var body: some View {
        ZStack {
            FirstGradientBackground()
            VStack (alignment: .leading){
                Text("Recommended Size")
                    .font(.heading32Medium)
                    .fontWeight(.medium)
//                    .padding(.top)
                
                VStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.width * 0.2)
                            .foregroundColor(Color(AppColors.primaryPurple))
                            .overlay(
                                Text("XL")
                                    .foregroundColor(.white)
                                    .font(.system(size: 48))
                                    .fontWeight(.bold)
                            )
                    }
                    .padding(.bottom, -48)
                    .padding(.top, -8)
                    .zIndex(1)
                    VStack (alignment: .leading, spacing: 8){
                        Text("Fit Preference")
                            .font(.body16Regular)
                            
                        Text("Looser fit may not be available for this item")
                            .font(.caption14Italic)
                            .foregroundStyle(notAvailableStatus ? Color.black.opacity(0.5) : Color.black.opacity(0))
                        SliderWithLabels()
                            .padding(.horizontal, -16)
                        
                        ZStack {
                            Image("chest_yellow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
                            Image("arm_length_green")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
                        }
                        .padding(.bottom, -42)
                        .padding(.leading, UIScreen.main.bounds.width * 0.05)
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.black, Color(hex: "FEC901").opacity(0.5))
                                .font(.system(size: 24))
                            Text("Chest area slightly tight")
                                .font(.caption14Italic)
                                .foregroundStyle(Color(hex: "838383"))
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, AppColors.successGreen)
                                .font(.system(size: 24))
                            Text("Arm is just right")
                                .font(.caption14Italic)
                                .foregroundStyle(Color(hex: "838383"))
                        }
                    }
                    .padding(8)
                    .padding(.top, 38)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    Text("Note : Measurements can differ by ± 1 – 2 cm due to material variation.")
                        .font(.caption14Italic)
                        .foregroundStyle(Color(hex: "838383"))
                        .padding(.vertical, 4)
                }
                VStack {
                    RoolaButton(buttonTitle: "Save Result", buttonColor: AppColors.primaryPurple, action: {})
                    RoolaButton(buttonTitle: "Try Again", buttonColor: AppColors.primaryWhite, action: {})
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct SliderWithLabels: View {
    
    @State var sliderValue: Float = 0.0

    let labels = ["Tight", "Slim", "Standard", "Relaxed", "Loose"]

    var body: some View {
        VStack {
            
            Slider(
                value: $sliderValue,
                in: 0...4,
                step: 1
            ) { didChange in
                print("Did change: \(didChange)")
            }
            .padding(.horizontal)
            .tint(Color(AppColors.primaryPurple))
            .padding(.bottom, -16)

            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { index in
                    let isSelected = (Int(round(sliderValue)) == index)
                    
                    VStack(spacing: 4) {
                        Text("•")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                        
                        Text(labels[index])
                            .font(.caption)
                            .foregroundColor(.black)
                            .fontWeight(.regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, -8)
        }
    }
}

#Preview {
//    ResultsView(viewModel: RecommendationViewModel(), showResults: .constant(true))
    ResultsView()
}
