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
    var onTap: () -> Void // 1. Tambahkan parameter onTap
    
    // State
    @State private var offset: CGFloat = 0
    @State private var isRemoved: Bool = false
    @State private var isSwiped: Bool = false
    
    // Config
    private let buttonWidth: CGFloat = 75
    private let cornerRadius: CGFloat = 12
    
    // 2. Update Init
    init(@ViewBuilder content: () -> Content, onTap: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            
            // MARK: - BACKGROUND LAYER (MERAH)
            if !isRemoved {
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppColors.errorRed)
                        .padding(.leading, 50)
                    
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
                .opacity(offset < 0 ? 1 : 0)
            }

            // MARK: - FOREGROUND (CARD)
            content
                .background(Color.white)
                .cornerRadius(cornerRadius)
                .offset(x: offset)
                // 3. Tambahkan Tap Gesture Manual di sini
                // Ini jauh lebih 'strict' daripada NavigationLink.
                // Dia hanya akan jalan kalau benar-benar Tap (bukan geser).
                .onTapGesture {
                    if offset == 0 { // Hanya bisa diklik kalau card tidak sedang terbuka
                        onTap()
                    } else {
                        // Kalau sedang terbuka dan diklik, tutup card-nya
                        withAnimation(.spring()) {
                            offset = 0
                            isSwiped = false
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let translation = value.translation.width
                            let verticalMovement = value.translation.height
                            
                            // Cegah swipe jika gerakan dominan vertikal (scroll)
                            if abs(verticalMovement) > abs(translation) { return }
                            
                            withAnimation(.interactiveSpring()) {
                                if isSwiped {
                                    if translation > 0 {
                                        let newPos = -buttonWidth + translation
                                        self.offset = min(0, newPos)
                                    } else {
                                        self.offset = -buttonWidth + (translation / 3)
                                    }
                                } else {
                                    if translation < 0 {
                                        self.offset = translation
                                    } else {
                                        self.offset = translation / 3
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            let verticalMovement = value.translation.height
                            
                            if abs(verticalMovement) > abs(translation) {
                                withAnimation(.spring()) {
                                    if isSwiped { offset = -buttonWidth }
                                    else { offset = 0 }
                                }
                                return
                            }
                            
                            let threshold = buttonWidth / 2
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSwiped {
                                    if translation > threshold {
                                        self.isSwiped = false
                                        self.offset = 0
                                    } else {
                                        self.offset = -buttonWidth
                                        if translation < -100 { deleteItem() }
                                    }
                                } else {
                                    if translation < -threshold {
                                        self.isSwiped = true
                                        self.offset = -buttonWidth
                                        if translation < -200 { deleteItem() }
                                    } else {
                                        self.offset = 0
                                        self.isSwiped = false
                                    }
                                }
                            }
                        }
                )
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
