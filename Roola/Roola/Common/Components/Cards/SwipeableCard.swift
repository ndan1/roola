//
//  SwipeableCard.swift
//  Roola
//
//  Created by Lin Dan Christiano on 26/11/25.
//

import SwiftUI

struct SwipeableCard<Content: View>: View {
    var content: Content
    var onDelete: () -> Void
    
    // State
    @State private var offset: CGFloat = 0
    @State private var isRemoved: Bool = false
    @State private var isSwiped: Bool = false
    
    // Config
    private let buttonWidth: CGFloat = 85
    private let cornerRadius: CGFloat = 12
    
    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            
            // MARK: - BACKGROUND LAYER (MERAH)
            if !isRemoved {
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppColors.errorRed)
                        .padding(.leading, 2)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.title3)
                        Text("Trash")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        deleteItem()
                    }
                }
                // Merah hanya muncul jika posisi card di sebelah kiri (offset negatif)
                .opacity(offset < 0 ? 1 : 0)
            }

            // MARK: - FOREGROUND (CARD)
            content
                .background(Color.white)
                .cornerRadius(cornerRadius)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            
                            withAnimation(.interactiveSpring()) {
                                if isSwiped {
                                    // KONDISI: CARD SUDAH TERBUKA
                                    // Kita hitung dari posisi terbuka (-buttonWidth)
                                    
                                    if translation > 0 {
                                        // User geser ke kanan (Menutup)
                                        // Gerakannya linear mengikuti jari dari titik -85 menuju 0
                                        // Kita pakai min(0, ...) supaya tidak bablas ke kanan banget
                                        let newPos = -buttonWidth + translation
                                        self.offset = min(0, newPos) // Mentok di 0 (posisi tertutup)
                                    } else {
                                        // User geser makin ke kiri (Resistance)
                                        self.offset = -buttonWidth + (translation / 3)
                                    }
                                } else {
                                    // KONDISI: CARD TERTUTUP (NORMAL)
                                    if translation < 0 {
                                        // User geser ke kiri (Membuka)
                                        self.offset = translation
                                    } else {
                                        // User geser ke kanan (Rubber Band)
                                        self.offset = translation / 3
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            // Tentukan snap point (kembali tertutup atau tetap terbuka)
                            let threshold = buttonWidth / 2
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSwiped {
                                    // Jika dari posisi terbuka, digeser ke kanan cukup jauh -> Tutup
                                    if value.translation.width > threshold {
                                        self.isSwiped = false
                                        self.offset = 0
                                    } else {
                                        // Balik ke posisi terbuka
                                        self.offset = -buttonWidth
                                        
                                        // Cek delete instant
                                        if value.translation.width < -100 {
                                            deleteItem()
                                        }
                                    }
                                } else {
                                    // Jika dari posisi tertutup, digeser ke kiri cukup jauh -> Buka
                                    if value.translation.width < -threshold {
                                        self.isSwiped = true
                                        self.offset = -buttonWidth
                                        
                                        // Cek delete instant
                                        if value.translation.width < -200 {
                                            deleteItem()
                                        }
                                    } else {
                                        // Balik tertutup
                                        self.offset = 0
                                        self.isSwiped = false
                                    }
                                }
                            }
                        }
                )
                // Tap body untuk menutup
                .onTapGesture {
                    if isSwiped {
                        withAnimation(.spring()) {
                            offset = 0
                            isSwiped = false
                        }
                    }
                }
        }
        .opacity(isRemoved ? 0 : 1)
        .frame(height: isRemoved ? 0 : nil, alignment: .top)
        .clipped()
    }
    
    private func deleteItem() {
        withAnimation(.spring()) {
            isRemoved = true
            offset = -UIScreen.main.bounds.width
            onDelete()
        }
    }
}
