//
//  OverlayViewModel.swift
//  Picklet
//
//  Created on 2025/05/07.
//

import Combine
import SwiftUI

/// アプリ全体のオーバーレイ表示を管理するViewModel
class OverlayViewModel: ObservableObject {
  // オーバーレイ表示状態
  @Published var isOverlayPresented = false

  // オーバーレイの不透明度（0.0-1.0）
  @Published var overlayOpacity = 0.5

  // オーバーレイの背景色
  @Published var overlayColor = Color.black

  // オーバーレイに表示するコンテンツ
  @Published var overlayContent: AnyView?

  /// オーバーレイを表示する
  /// - Parameters:
  ///   - content: 表示するコンテンツ
  ///   - opacity: 背景の不透明度
  ///   - color: 背景の色
  func showOverlay<Content: View>(
    content: Content,
    opacity: Double = 0.5,
    color: Color = .black) {
    overlayContent = AnyView(content)
    overlayOpacity = opacity
    overlayColor = color
    isOverlayPresented = true
  }

  /// オーバーレイを非表示にする
  func hideOverlay() {
    isOverlayPresented = false
  }
}
