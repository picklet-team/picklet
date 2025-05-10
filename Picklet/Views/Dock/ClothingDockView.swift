import Combine
import SDWebImageSwiftUI
import SwiftUI

// MARK: - Helper types

/// Wrapper so we can use UUID in sheet/navigationDestination
struct IdentifiableUUID: Identifiable, Hashable { let id: UUID }

/// Exponential‑moving‑average cursor smoother
private struct CursorSmoother {
  private(set) var raw: CGFloat = -1_000 // last tapped / dragged target X
  private(set) var ema: CGFloat = -1_000 // smoothed X used for UI
  private let alpha: CGFloat = 0.25 // smoothing factor (0‥1)
  mutating func setTarget(_ targetX: CGFloat) { raw = targetX }
  mutating func step() { ema += alpha * (raw - ema) }
  var reachedTarget: Bool { abs(raw - ema) < 0.5 }
}

// MARK: - Dock View

struct ClothingDockView: View {
  let itemWidth = UIScreen.main.bounds.width * 0.38
  let itemHeight = UIScreen.main.bounds.width * 0.38
  let horizontalPadding = 15.0

  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var overlayManager: GlobalOverlayManager // オーバーレイマネージャー

  // 共通のImageLoaderServiceを使用
  private let imageLoaderService = ImageLoaderService.shared

  // configuration
  private let maxCards = 20
  private let cardWidth: CGFloat = 120
  private let influence: CGFloat = 160
  private let sideMargin: CGFloat = 0.2

  // cursor smoothing
  @State private var smoother = CursorSmoother()
  @State private var smoothingOn = false

  // Peek & Pop state
  @State private var previewId: IdentifiableUUID?
  @State private var lastSelectedId: UUID? // 追加: 最後に選択されたIDを記録
  @State private var commitId: UUID?

  // timer
  private let tick = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geo in
      ZStack {
        let items = Array(viewModel.clothes.prefix(maxCards))
        let centreX = geo.size.width / 2

        ForEach(Array(zip(viewModel.clothes.indices, $viewModel.clothes)), id: \.1.id) { idx, $clothing in
          let baseX = baseOffsetX(idx: idx, total: items.count, width: geo.size.width)
          let deltaX = smoother.ema - baseX
          let tValue = clamp(1 - abs(deltaX) / influence, 0, 1)
          let angle = Angle(radians: -Double(atan(deltaX / (cardWidth / 2))))
          let scale = 1 / (2 - tValue)

          ClothingCardView(
            clothing: $clothing,
            imageURL: viewModel.imageSetsMap[clothing.id]?.first?.originalUrl,
            angle: angle,
            scale: scale,
            xOffset: baseX - centreX,
            zIndex: Double(tValue),
            onPeek: {
              // 修正: 同じアイテムを再選択できるようにする
              if previewId?.id == clothing.id {
                // 既に選択されているアイテムの場合、一度nilにしてから再設定
                previewId = nil
                // 少し遅延を入れて状態の変更を確実に検出させる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  previewId = IdentifiableUUID(id: clothing.id)
                }
              } else {
                previewId = IdentifiableUUID(id: clothing.id)
              }
            },
            onPopAttempt: {})
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      // drag
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in setCursor(to: value.location.x) })
      // smoother tick
      .onReceive(tick) { _ in stepSmoother() }
      // オーバーレイを使わず直接表示変更を監視
      .onChange(of: previewId) { oldValue, newValue in
        if let wrap = newValue,
           let cloth = viewModel.clothes.first(where: { $0.id == wrap.id }) {
          // 選択されたIDを記録
          lastSelectedId = wrap.id

          // QuickView表示時にImageLoaderServiceを使用
          let imageURL = viewModel.imageSetsMap[cloth.id]?.first?.originalUrl

          // GlobalOverlayManagerを使用してClothingQuickViewを表示
          overlayManager.present(
            ClothingQuickView(
              clothingId: cloth.id, // clothingIdを渡して画像読み込みに使用
              imageURL: imageURL,
              name: cloth.name,
              category: cloth.category,
              color: cloth.color)
              .environmentObject(viewModel) // ここにEnvironmentObjectを追加
              .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
              .shadow(radius: 10)
              .onTapGesture {
                commitId = cloth.id
                overlayManager.dismiss()
                previewId = nil
              }
              .padding(30))
        } else if oldValue != nil && newValue == nil {
          // プレビューが閉じられたらオーバーレイも閉じる
          overlayManager.dismiss()
        }
      }
      // オーバーレイクローズ時の処理を追加
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        // アプリがフォアグラウンドに戻ったときに状態をリセット（保険的対応）
        if previewId != nil && !overlayManager.isPresented {
          previewId = nil
        }
      }
      // pop navigation
      .navigationDestination(item: $commitId) { id in
        if let binding = bindingFor(id: id) {
          ClothingDetailView(clothing: binding, clothingId: id)
            .environmentObject(viewModel)
        }
      }
      .task { // initial centre
        if smoother.raw < 0 { setCursor(to: geo.size.width / 2) }
      }
    }
  }

  // MARK: – Cursor helpers

  private func setCursor(to cursorX: CGFloat) {
    smoother.setTarget(cursorX)
    smoothingOn = true
  }

  private func stepSmoother() {
    guard smoothingOn else { return }
    smoother.step()
    if smoother.reachedTarget { smoothingOn = false }
  }

  // MARK: – Utilities

  private func baseOffsetX(idx: Int, total: Int, width: CGFloat) -> CGFloat {
    let usable = width * (1 - 2 * sideMargin)
    return width * sideMargin + usable * CGFloat(idx) / CGFloat(max(total - 1, 1))
  }

  private func bindingFor(id: UUID) -> Binding<Clothing>? {
    guard let index = viewModel.clothes.firstIndex(where: { $0.id == id }) else { return nil }
    return $viewModel.clothes[index]
  }

  private func clamp<T: Comparable>(_ value: T, _ minValue: T, _ maxValue: T) -> T {
    min(max(value, minValue), maxValue)
  }
}
