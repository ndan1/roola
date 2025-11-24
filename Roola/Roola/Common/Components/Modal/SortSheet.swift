//
//  SortSheet.swift
//  Roola
//
//  Created by Hendrik Nicolas Carlo on 12/11/25.
//

import SwiftUI

struct SortSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSort: String
    
    let sortOptions = ["Newest", "Last 7 days", "Last 30 days"]
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 5)
                .padding(.top, 12)
            
            HStack {
                Spacer()
                Text("Sort by")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 24)
            .overlay(alignment: .trailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding(.trailing, 20)
                }
            }
            
            VStack(spacing: 0) {
                ForEach(sortOptions, id: \.self) { option in
                    Button(action: { selectedSort = option }) {
                        HStack {
                            Text(option)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Circle()
                                .stroke(AppColors.primaryPurple, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(AppColors.primaryPurple)
                                        .frame(width: 14, height: 14)
                                        .opacity(selectedSort == option ? 1 : 0)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primaryPurple)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

#Preview {
    SortSheet(selectedSort: .constant("Newest"))
}
