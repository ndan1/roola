//
//  ContentView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingSheet = false
    @State private var showingData = false
    @State private var showingUserInput = false
    
    @Query var clothes: [Clothes]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 20) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        showingData.toggle()
                    }
                    .sheet(isPresented: $showingData) {
                        DataView()
                    }
                
                Text("Welcome to Roola")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Get your perfect size, every time.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Button("Get Started Now") {
                    showingSheet.toggle()
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(radius: 4)
                .padding(.top, 10)
                
                Button("Enter Body Measurements") {
                    showingUserInput.toggle()
                }
                .font(.subheadline)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $showingSheet) {
            if let firstClothingItem = clothes.first {
                SheetView(clothes: firstClothingItem)
                    .presentationDetents([.medium])
                    .background(Color(UIColor.systemBackground))
            } else {
                Text("Loading clothing data...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
            }
        }
        .sheet(isPresented: $showingUserInput) {
            UserInputView()
        }
    }
}
