import Combine
import SDWebImageSwiftUI
import SwiftUI

// MARK: - Helper types

struct IdentifiableUUID: Identifiable, Hashable { let id: UUID }

// MARK: - Dock View

struct ClothingDockView: View {
  let itemWidth = UIScreen.main.bounds.width * 0.38
  let itemHeight = UIScreen.main.bounds.width * 0.38
  let horizontalPadding = 15.0

  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var overlayManager: GlobalOverlayManager
  @EnvironmentObject private var themeManager: ThemeManager

  private let imageLoaderService = ImageLoaderService.shared

  // 円形レイアウト設定
  private let maxCards = 20
  private let baseRadius: CGFloat = 80
  private let radiusMultiplier: CGFloat = 12
  private let cardSize: CGFloat = 80

  // 共通の回転コントローラーを使用
  @StateObject private var rotationController = RotationController()

  // Peek & Pop state
  @State private var previewId: IdentifiableUUID?
  @State private var lastSelectedId: UUID?
  @State private var commitId: UUID?

  // ジェスチャー競合を防ぐためのState
  @State private var isCardDragging: Bool = false

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // 透明な背景領域で回転ジェスチャーを受け取る
        Rectangle()
          .fill(Color.clear)
          .contentShape(Rectangle())
          .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
              .onChanged { value in
                guard !isCardDragging else { return }

                // グローバル座標での回転中心を計算
                let globalCenterPoint = geo.frame(in: .global).center

                // 共通コントローラーを使用（バックグラウンドドラッグ）
                rotationController.handleDrag(
                  currentPoint: value.location,
                  centerPoint: globalCenterPoint,
                  isCardDrag: false)
              }
              .onEnded { _ in
                guard !isCardDragging else { return }
                rotationController.endDrag()
              })

        ForEach(Array(viewModel.clothes.prefix(maxCards).enumerated()), id: \.element.id) { idx, clothing in
          clothingCardView(
            for: clothing,
            at: idx,
            centerPoint: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2),
            totalItems: min(viewModel.clothes.count, maxCards),
            geo: geo)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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

  // 1つ目のメソッド: カードビューの作成（パラメータを減らす）
  @ViewBuilder
  private func clothingCardView(
    for clothing: Clothing,
    at index: Int,
    centerPoint: CGPoint, // centerXとcenterYを一つにまとめる
    totalItems: Int,
    geo: GeometryProxy) -> some View {
    let centerX = centerPoint.x
    let centerY = centerPoint.y

    let position = calculatePosition(index: index, centerX: centerX, centerY: centerY, totalItems: totalItems)
    let scale = calculateScale(yPosition: position.y, centerY: centerY, totalItems: totalItems)
    let zIndex = calculateZIndex(yPosition: position.y, centerY: centerY, totalItems: totalItems)
    let cardRotation = calculateCardRotation(index: index, totalItems: totalItems, centerX: centerX, centerY: centerY)
    let xOffsetValue: CGFloat = position.x - centerX
    let yOffsetValue: CGFloat = (position.y - centerY) * 0.3

    ClothingCardView(
      clothing: .constant(clothing),
      imageURL: viewModel.imageSetsMap[clothing.id]?.first?.originalUrl,
      angle: Angle(radians: cardRotation),
      scale: scale,
      xOffset: xOffsetValue,
      zIndex: zIndex,
      onTap: { handleClick(for: clothing.id) },
      onDrag: { location in
        isCardDragging = true

        // グローバル座標での回転中心を計算
        let globalCenterPoint = geo.frame(in: .global).center

        // 共通コントローラーを使用（カードドラッグ）
        rotationController.handleDrag(
          currentPoint: location,
          centerPoint: globalCenterPoint,
          isCardDrag: false)
      },
      onDragEnd: {
        isCardDragging = false
        rotationController.endDrag()
      })
      .offset(y: yOffsetValue)
      .allowsHitTesting(true)
      .zIndex(zIndex)
  }

  // MARK: - Calculations（rotationController.currentRotationを使用）

  private func calculateRadius(for totalItems: Int) -> CGFloat {
    return baseRadius + CGFloat(totalItems) * radiusMultiplier
  }

  private func calculatePosition(index: Int, centerX: CGFloat, centerY: CGFloat, totalItems: Int) -> CGPoint {
    let radius = calculateRadius(for: totalItems)
    let anglePerItem: Double = 2 * Double.pi / Double(totalItems)
    let itemAngle: Double = rotationController.currentRotation + Double(index) * anglePerItem

    let xPos: CGFloat = centerX + CGFloat(cos(itemAngle)) * radius
    let yPos: CGFloat = centerY + CGFloat(sin(itemAngle)) * radius

    return CGPoint(x: xPos, y: yPos)
  }

  private func calculateScale(yPosition: CGFloat, centerY: CGFloat, totalItems: Int) -> CGFloat {
    let radius = calculateRadius(for: totalItems)

    // 相対的なY位置（-1.0から1.0の範囲）を計算
    let relativeY = (yPosition - centerY) / radius

    // -1.0（最も奥）→0.4倍、+1.0（最も手前）→1.0倍のスケール
    return 0.4 + 0.3 * (relativeY + 1.0)
  }

  private func calculateZIndex(yPosition: CGFloat, centerY: CGFloat, totalItems: Int) -> Double {
    let radius = calculateRadius(for: totalItems)

    // 相対的なY位置（-1.0から1.0の範囲）を計算
    let relativeY = (yPosition - centerY) / radius

    // 下にあるカード（正のrelativeY）ほど高いzIndexを持つように
    // 整数部の大きな値を使用して確実に重なりが正しく表示されるようにする
    return relativeY * 1_000.0
  }

  private func calculateCardRotation(index: Int, totalItems: Int, centerX: CGFloat, centerY: CGFloat) -> Double {
    let anglePerItem: Double = 2 * Double.pi / Double(totalItems)
    let itemAngle: Double = rotationController.currentRotation + Double(index) * anglePerItem

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

  // MARK: - Helper Methods

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
          imageURL: imageURL)
          .environmentObject(viewModel)
          .environmentObject(themeManager) // テーママネージャーも追加
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

// CGRectの拡張を追加
extension CGRect {
  var center: CGPoint {
    return CGPoint(x: midX, y: midY)
  }
}
