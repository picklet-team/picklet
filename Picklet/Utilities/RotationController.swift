import SwiftUI

/// 回転操作を管理する共通コントローラー
@MainActor
class RotationController: ObservableObject {
  @Published var currentRotation: Double = 0
  @Published var velocity: Double = 0

  private var lastDragPosition: CGPoint = .zero
  private var timer: Timer?

  /// ドラッグ操作による回転処理
  /// - Parameters:
  ///   - currentPoint: 現在の指の位置（グローバル座標）
  ///   - centerPoint: 回転中心（グローバル座標）
  ///   - isCardDrag: カードをドラッグしているかどうか（現在は使用しない）
  func handleDrag(currentPoint: CGPoint, centerPoint: CGPoint, isCardDrag: Bool = false) {
    // ジェスチャー開始時の処理
    if lastDragPosition == .zero {
      lastDragPosition = currentPoint
      return
    }

    // 角度の計算
    let previousAngle = calculateAngle(from: centerPoint, to: lastDragPosition)
    let currentAngle = calculateAngle(from: centerPoint, to: currentPoint)

    // 角度の差分を計算（統一された方向）
    var angleDifference = currentAngle - previousAngle

    // 角度の不連続性を処理（-πからπへの遷移など）
    if angleDifference > .pi {
      angleDifference -= 2 * .pi
    } else if angleDifference < -.pi {
      angleDifference += 2 * .pi
    }

    // 回転量が大きすぎる場合は抑制（急激な変化を防ぐ）
    if abs(angleDifference) > 0.3 {
      angleDifference = angleDifference > 0 ? 0.3 : -0.3
    }

    // センシングを弱める（感度を下げる）
    angleDifference *= 0.6

    // 回転を更新
    currentRotation += angleDifference
    velocity = angleDifference * 1.5

    lastDragPosition = currentPoint
  }

  /// ドラッグ終了時の処理
  func endDrag() {
    lastDragPosition = .zero
    startInertialRotation()
  }

  /// 慣性回転を開始
  func startInertialRotation() {
    timer?.invalidate()

    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
      guard let self = self else { return }

      Task { @MainActor in
        self.currentRotation += self.velocity
        self.velocity *= 0.98

        if abs(self.velocity) < 0.002 {
          self.timer?.invalidate()
          self.timer = nil
        }
      }
    }
  }

  /// 角度を計算するヘルパー
  private func calculateAngle(from center: CGPoint, to point: CGPoint) -> Double {
    return atan2(Double(point.y - center.y), Double(point.x - center.x))
  }

  /// タイマーを停止
  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  deinit {
    let currentTimer = timer
    timer = nil
    currentTimer?.invalidate()
  }
}
