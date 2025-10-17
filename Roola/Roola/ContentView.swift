//
//  ContentView.swift
//  Roola
//
//  Created by Georgius Kenny Gunawan on 17/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSheet = false
    var body: some View {
        VStack {
            Button {
                showingSheet.toggle()
            } label: {
                Text("Click me")
            }
            .sheet(isPresented: $showingSheet) {
                SheetView()
            }
        }
        .padding()
    }
}

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSize: String = "XL"
    
    let sizes = ["S", "M", "L", "XL"]
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 30){
                VStack(spacing: 30){
                    Text("Your Best Size is")
                        .font(.title2)
                        .padding(.top, 20)
                    
                    // Size Selection Buttons
                    Text(selectedSize)
                        .font(.title2)
                    
                    HStack(spacing: 5) {
                        ForEach(sizes, id: \.self) { size in
                            Button(action: {
                                selectedSize = size
                            }) {
                                Text(size)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .frame(width: 40, height: 40)
                                    .background(selectedSize == size ? Color.black : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedSize == size ? Color.white : Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedSize == size ? Color.black : Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                
                Rectangle()
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 120, height: 160)
            }
            
            
            
            
            Button("Press to dismiss") {
                dismiss()
            }
            .font(.title)
            .padding()
            .background(.black)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        Spacer()
    }
}


#Preview {
    ContentView()
}
