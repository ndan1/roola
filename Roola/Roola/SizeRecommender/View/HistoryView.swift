//
//  HistoryView.swift
//  Roola
//
//  Created by F Rachell K on 10/11/25.
//

import SwiftUI

struct HistoryItem: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let date: String
    let initial: String
}

struct HistoryView: View {
    @State private var historyItems: [HistoryItem] = [
        HistoryItem(name: "Jennie Blouse", location: "Shop at Velvet", date: "10 Apr 2025", initial: "M"),
        HistoryItem(name: "Jennie Blouse", location: "Shop at Velvet", date: "10 Apr 2025", initial: "M"),
        HistoryItem(name: "Jennie Blouse", location: "Shop at Velvet", date: "07 Apr 2025", initial: "M")
    ]
    @State private var showSortSheet = false
    @State private var selectedSort = "Last 7 days"
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if historyItems.isEmpty {
                        EmptyHistoryView()
                    } else {
                        VStack{
                            HStack{
                                RoolaHeader(
                                    title: "History",
                                    isLargeTitle: true
                                )
                                
                                Button(action: {
                                    showSortSheet = true
                                }) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primaryPurple)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 16)
                            }
                            .padding(.top, 18)
                            
                            HistoryListView(items: historyItems)
                        }
                    }
                }
                .background(FirstGradientBackground().ignoresSafeArea())
            }
            .sheet(isPresented: $showSortSheet) {
                SortSheet(selectedSort: $selectedSort)
                    .presentationDetents([.height(350)])
            }
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: UIScreen.main.bounds.height * 0.15)
            VStack(spacing: 64) {
                Spacer()
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 65))
                    .foregroundColor(AppColors.primaryPurple)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 120, height: 120)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Start inputing your desire outfit and \nget recommendations")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.leading, 30)
                    
                    VStack(spacing: 16) {
                        InstructionRow(icon: "sparkles", text: "Fill in your measurements manually or use our AI")
                        InstructionRow(icon: "sparkles", text: "Fill in your product details to get your best match")
                    }
                    .padding(.horizontal, 26)
                    
                    Spacer()
                }
            }
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryPurple)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppColors.primaryWhite)
                    .font(.system(size: 18))
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(AppColors.primaryBlack)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct HistoryListView: View {
    let items: [HistoryItem]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    HistoryCard(item: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct HistoryCard: View {
    let item: HistoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryPurple)
                    .frame(width: 60, height: 80)
                
                Text(item.initial)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primaryWhite)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(AppColors.primaryBlack)
                
                Text(item.location)
                    .font(.subheadline)
                    .foregroundColor(AppColors.grayScale400)
            }
            
            Spacer()
            
            VStack {
                Text(item.date)
                    .font(.subheadline)
                    .foregroundColor(AppColors.grayScale400)
                Spacer()
            }
        }
        .padding(16)
        .background(AppColors.primaryWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}


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

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
