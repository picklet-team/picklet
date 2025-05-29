import Combine
import SDWebImageSwiftUI
import SwiftUI

// MARK: - Helper types

/// Wrapper so we can use UUID in sheet/navigationDestination
struct IdentifiableUUID: Identifiable, Hashable { let id: UUID }

// MARK: - Dock View

struct ClothingDockView: View {
  let itemWidth = UIScreen.main.bounds.width * 0.38
  let itemHeight = UIScreen.main.bounds.width * 0.38
  let horizontalPadding = 15.0

  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var overlayManager: GlobalOverlayManager

  private let imageLoaderService = ImageLoaderService.shared

  // 円形レイアウト設定
  private let maxCards = 20
  private let baseRadius: CGFloat = 80 // 基本半径を大きく
  private let radiusMultiplier: CGFloat = 12 // アイテム数に応じた半径の増加率を大きく
  private let cardSize: CGFloat = 80 // カードサイズ

  // 回転制御
  @State private var currentRotation: Double = 0 // 現在の回転角度（ラジアン）
  @State private var lastDragValue: CGFloat = 0
  @State private var velocity: Double = 0 // 慣性用の速度
  @State private var timer: Timer? // 慣性アニメーション用

  // タップ/ドラッグ判定用
  @State private var gestureStartTime: Date? // ジェスチャー開始時刻
  @State private var hasMoved: Bool = false // 移動したかどうか

  // Peek & Pop state
  @State private var previewId: IdentifiableUUID?
  @State private var lastSelectedId: UUID?
  @State private var commitId: UUID?

  var body: some View {
    GeometryReader { geo in
      ZStack {
        ForEach(Array(viewModel.clothes.prefix(maxCards).enumerated()), id: \.element.id) { idx, clothing in
          clothingCardView(
            for: clothing,
            at: idx,
            centerX: geo.size.width / 2,
            centerY: geo.size.height / 2,
            totalItems: min(viewModel.clothes.count, maxCards))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
      .gesture(rotationGesture)
      .onChange(of: previewId) { oldValue, newValue in
        handlePreviewChange(oldValue: oldValue, newValue: newValue)
      }
      .navigationDestination(item: $commitId) { id in
        if let binding = bindingFor(id: id) {
          ClothingDetailView(clothing: binding, clothingId: id)
            .environmentObject(viewModel)
        }
      }
    }
  }

  // MARK: - View Builders

  @ViewBuilder
  private func clothingCardView(
    for clothing: Clothing,
    at index: Int,
    centerX: CGFloat,
    centerY: CGFloat,
    totalItems: Int) -> some View {
    let position = calculatePosition(index: index, centerX: centerX, centerY: centerY, totalItems: totalItems)
    let scale = calculateScale(yPosition: position.y, centerY: centerY, totalItems: totalItems)
    let zIndex = calculateZIndex(yPosition: position.y, centerY: centerY, totalItems: totalItems)
    let cardRotation = calculateCardRotation(index: index, totalItems: totalItems, centerX: centerX, centerY: centerY)
    let xOffsetValue: CGFloat = position.x - centerX
    let yOffsetValue: CGFloat = (position.y - centerY) * 0.3 // 上下の差を小さく

    ClothingCardView(
      clothing: .constant(clothing),
      imageURL: viewModel.imageSetsMap[clothing.id]?.first?.originalUrl,
      angle: Angle(radians: cardRotation),
      scale: scale,
      xOffset: xOffsetValue,
      zIndex: zIndex,
      onPeek: {
        // 長押し用（必要に応じて）
      },
      onPopAttempt: {})
      .offset(y: yOffsetValue)
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if gestureStartTime == nil {
              gestureStartTime = Date()
              hasMoved = false
            }

            // 移動距離が一定以上、または時間が一定以上ならドラッグとして処理
            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            let timeElapsed = Date().timeIntervalSince(gestureStartTime ?? Date())

            if distance > 5 || timeElapsed > 0.2 {
              hasMoved = true
              // ドラッグ処理（回転速度を遅く）
              let dragDistance: CGFloat = value.translation.width - lastDragValue
              currentRotation -= Double(dragDistance) * 0.004
              lastDragValue = value.translation.width
              velocity = -Double(dragDistance) * 0.004
            }
          }
          .onEnded { value in
            defer {
              gestureStartTime = nil
              lastDragValue = 0
              hasMoved = false
            }

            // 短いタップで移動距離が小さい場合はクリックとして処理
            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            let timeElapsed = Date().timeIntervalSince(gestureStartTime ?? Date())

            if !hasMoved, distance <= 5, timeElapsed <= 0.2 {
              // クリック処理
              handleClick(for: clothing.id)
            } else {
              // ドラッグ終了処理（慣性のみ、スナップなし）
              startInertialRotation()
            }
          })
  }

  // MARK: - Calculations

  private func calculateRadius(for totalItems: Int) -> CGFloat {
    return baseRadius + CGFloat(totalItems) * radiusMultiplier
  }

  private func calculatePosition(index: Int, centerX: CGFloat, centerY: CGFloat, totalItems: Int) -> CGPoint {
    let radius = calculateRadius(for: totalItems)
    let anglePerItem: Double = 2 * Double.pi / Double(totalItems)
    let itemAngle: Double = currentRotation + Double(index) * anglePerItem

    let xPos: CGFloat = centerX + CGFloat(cos(itemAngle)) * radius
    let yPos: CGFloat = centerY + CGFloat(sin(itemAngle)) * radius

    return CGPoint(x: xPos, y: yPos)
  }

  private func calculateScale(yPosition: CGFloat, centerY: CGFloat, totalItems: Int) -> CGFloat {
    let radius = calculateRadius(for: totalItems)
    // 手前（下）が大きく、奥（上）が小さくなるように調整（遠近法）
    let normalizedY: CGFloat = (yPosition - centerY + radius) / (2 * radius)
    return 0.4 + 0.6 * normalizedY // 手前（下側/画面下部）が大きく、奥（上側/画面上部）がもっと小さく
  }

  private func calculateZIndex(yPosition: CGFloat, centerY: CGFloat, totalItems: Int) -> Double {
    let radius = calculateRadius(for: totalItems)
    // 手前（下）が前面に、奥（上）が背面になるように調整
    let normalizedY: CGFloat = (yPosition - centerY + radius) / (2 * radius)
    return Double(normalizedY) * 1_000 // 手前（下側/画面下部）が前面に
  }

  private func calculateCardRotation(index: Int, totalItems: Int, centerX: CGFloat, centerY: CGFloat) -> Double {
    let anglePerItem: Double = 2 * Double.pi / Double(totalItems)
    let itemAngle: Double = currentRotation + Double(index) * anglePerItem

    // アイテムの位置を計算
    let radius = calculateRadius(for: totalItems)
    let itemX = centerX + CGFloat(cos(itemAngle)) * radius
    let itemY = centerY + CGFloat(sin(itemAngle)) * radius

    // ユーザーの位置（中心より遠く設定して斜めを向く角度を緩やかに）
    let userX = centerX
    let userY = centerY + 400 // 200 → 300に変更（より遠くに設定）

    // アイテムからユーザーへの角度を計算
    let deltaX = userX - itemX
    let deltaY = userY - itemY
    let rotationAngle = atan2(deltaY, deltaX)

    return rotationAngle + Double.pi / 2 // 90度調整
  }

  // MARK: - Gestures

  private var rotationGesture: some Gesture {
    // カード個別のジェスチャーで処理するため、全体のジェスチャーは無効化または簡素化
    DragGesture()
      .onChanged { _ in }
      .onEnded { _ in }
  }

  // MARK: - Helper Methods

  private func startInertialRotation() {
    timer?.invalidate()

    // 慣性のみ（スナップ機能削除）
    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak timer] _ in
      Task { @MainActor in
        currentRotation += velocity
        velocity *= 0.98 // 減速をより緩やかに

        // 速度の閾値をより小さく（慣性を長く保つ）
        if abs(velocity) < 0.0001 {
          timer?.invalidate()
          self.timer = nil
          // スナップ削除
        }
      }
    }
  }

  private func snapToNearestItem(itemCount: Int) {
    guard itemCount > 0 else { return }

    let anglePerItem: Double = 2 * Double.pi / Double(itemCount)
    let currentIndex: Double = currentRotation / anglePerItem
    let nearestIndex: Double = round(currentIndex)
    let targetRotation: Double = nearestIndex * anglePerItem

    withAnimation(.easeOut(duration: 0.3)) {
      currentRotation = targetRotation
    }
  }

  private func handleClick(for clothingId: UUID) {
    // 同じアイテムの場合は一度クリアしてから再設定
    if previewId?.id == clothingId {
      previewId = nil
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        previewId = IdentifiableUUID(id: clothingId)
      }
    } else {
      previewId = IdentifiableUUID(id: clothingId)
    }
  }

  private func handlePreviewChange(oldValue: IdentifiableUUID?, newValue: IdentifiableUUID?) {
    if let wrap = newValue,
       let cloth = viewModel.clothes.first(where: { $0.id == wrap.id }) {
      lastSelectedId = wrap.id
      let imageURL = viewModel.imageSetsMap[cloth.id]?.first?.originalUrl

      overlayManager.present(
        ClothingQuickView(
          clothingId: cloth.id,
          imageURL: imageURL,
          name: cloth.name,
          category: cloth.category,
          color: cloth.color)
          .environmentObject(viewModel)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
          .shadow(radius: 10)
          .onTapGesture {
            commitId = cloth.id
            overlayManager.dismiss()
            previewId = nil
          }
          .padding(30))
    } else if oldValue != nil && newValue == nil {
      overlayManager.dismiss()
    }
  }

  private func bindingFor(id: UUID) -> Binding<Clothing>? {
    guard let index = viewModel.clothes.firstIndex(where: { $0.id == id }) else { return nil }
    return $viewModel.clothes[index]
  }
}
