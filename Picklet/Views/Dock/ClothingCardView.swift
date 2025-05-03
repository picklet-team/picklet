//
//  ClothingCardView.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI

struct ClothingCardView: View {
    @EnvironmentObject private var vm: ClothingViewModel
    @Binding var clothing: Clothing

    let imageURL: String?
    let angle: Angle
    let scale: CGFloat
    let xOffset: CGFloat
    let zIndex: Double
    let onPeek: () -> Void
    let onPopAttempt: () -> Void

    var body: some View {
        ClothingItemView(clothing: clothing, imageUrl: imageURL)
            .environmentObject(vm)
            .frame(width: 120)
            .rotation3DEffect(angle, axis: (0, -1, 0), perspective: 0.7)
            .scaleEffect(scale)
            .offset(x: xOffset)
            .zIndex(zIndex)
            .gesture(
                LongPressGesture(minimumDuration: 0.25, maximumDistance: 20)
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onPeek()
                    }
            )
    }
}
