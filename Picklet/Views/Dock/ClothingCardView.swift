//
//  ClothingCardView.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI

struct ClothingCardView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @Binding var clothing: Clothing

  let imageURL: String?
  let angle: Angle
  let scale: CGFloat
  let xOffset: CGFloat
  let zIndex: Double
  let onTap: () -> Void
  let onDrag: (CGFloat) -> Void
  let onDragEnd: () -> Void

  @State private var gestureStartTime: Date?
  @State private var hasMoved: Bool = false
  @State private var lastDragValue: CGFloat = 0

  var body: some View {
    ClothingItemView(clothing: clothing, imageUrl: imageURL)
      .environmentObject(viewModel)
      .frame(width: 120)
      .scaleEffect(x: -1, y: 1) // X軸方向に反転して正しい向きに
      .rotation3DEffect(angle, axis: (0, -1, 0), perspective: 0.7)
      .scaleEffect(scale)
      .offset(x: xOffset)
      .zIndex(zIndex)
      .gesture( // simultaneousGestureから.gestureに変更
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if gestureStartTime == nil {
              gestureStartTime = Date()
              hasMoved = false
              lastDragValue = 0
            }

            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            let timeElapsed = Date().timeIntervalSince(gestureStartTime ?? Date())

            if distance > 5 || timeElapsed > 0.2 {
              hasMoved = true
              // ドラッグ処理
              let dragDistance = value.translation.width - lastDragValue
              onDrag(dragDistance)
              lastDragValue = value.translation.width
            }
          }
          .onEnded { value in
            defer {
              gestureStartTime = nil
              hasMoved = false
              lastDragValue = 0
            }

            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            let timeElapsed = Date().timeIntervalSince(gestureStartTime ?? Date())

            if !hasMoved, distance <= 5, timeElapsed <= 0.2 {
              // タップ処理
              onTap()
            } else if hasMoved {
              // ドラッグ終了処理
              onDragEnd()
            }
          })
  }
}
