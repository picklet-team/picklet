import SwiftUI
import Combine

// MARK: - Helper types

/// Wrapper so we can use UUID in sheet/navigationDestination
struct IdentifiableUUID: Identifiable, Hashable { let id: UUID }

/// Exponential‑moving‑average cursor smoother
fileprivate struct CursorSmoother {
    private(set) var raw: CGFloat = -1000      // last tapped / dragged target X
    private(set) var ema: CGFloat = -1000      // smoothed X used for UI
    private let alpha: CGFloat = 0.25          // smoothing factor (0‥1)
    mutating func setTarget(_ x: CGFloat) { raw = x }
    mutating func step() { ema += alpha * (raw - ema) }
    var reachedTarget: Bool { abs(raw - ema) < 0.5 }
}

// MARK: - Quick pop‑up view (lightweight card)

struct ClothingQuickView: View {
    let imageURL: String?
    let name: String
    let category: String
    let color: String?

    var body: some View {
        VStack(spacing: 12) {
            if let urlStr = imageURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFit()
                    case .failure(_): Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
                    default: ProgressView()
                    }
                }
                .frame(width: 150, height: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            Text(name).font(.headline)
            Text(category).font(.subheadline).foregroundColor(.secondary)
            if let c = color {
                Text(c).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground)).cornerRadius(6)
            }
        }
        .padding(24)
    }
}

// MARK: - Single card view

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

// MARK: - Dock View

struct ClothingDockView: View {
    @EnvironmentObject private var vm: ClothingViewModel

    // configuration
    private let maxCards = 20
    private let cardWidth: CGFloat = 120
    private let influence: CGFloat = 160
    private let sideMargin: CGFloat = 0.2

    // cursor smoothing
    @State private var smoother = CursorSmoother()
    @State private var smoothingOn = false

    // Peek & Pop state
    @State private var previewId: IdentifiableUUID? = nil
    @State private var commitId: UUID? = nil

    // timer
    private let tick = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let items = Array(vm.clothes.prefix(maxCards))
                let centreX = geo.size.width / 2

                ForEach(Array(zip(vm.clothes.indices, $vm.clothes)), id: \.1.id) { idx, $clothing in
                    let baseX  = baseOffsetX(idx: idx, total: items.count, width: geo.size.width)
                    let dx     = smoother.ema - baseX
                    let t      = clamp(1 - abs(dx) / influence, 0, 1)
                    let angle  = Angle(radians: -Double(atan(dx / (cardWidth/2))))
                    let scale  = 1 / (2 - t)

                    ClothingCardView(
                        clothing: $clothing,
                        imageURL: vm.imageSetsMap[clothing.id]?.first?.originalUrl,
                        angle: angle,
                        scale: scale,
                        xOffset: baseX - centreX,
                        zIndex: Double(t),
                        onPeek: { previewId = IdentifiableUUID(id: clothing.id) },
                        onPopAttempt: { }
//                        onPopAttempt: { commitIfFront(id: clothing.id, dx: dx) }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // drag
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in setCursor(to: v.location.x) }
            )
            // smoother tick
            .onReceive(tick) { _ in stepSmoother() }
            // overlay (peek)
            .overlay { overlayQuickView() }
            // pop navigation
            .navigationDestination(item: $commitId) { id in
                if let binding = bindingFor(id: id) {
                    ClothingDetailView(clothing: binding, clothingId: id)
                        .environmentObject(vm)
                }
            }
            .task { // initial centre
                if smoother.raw < 0 { setCursor(to: geo.size.width/2) }
            }
        }
    }

    // MARK: – Cursor helpers
    private func setCursor(to x: CGFloat) {
        smoother.setTarget(x)
        smoothingOn = true
    }
    private func stepSmoother() {
        guard smoothingOn else { return }
        smoother.step()
        if smoother.reachedTarget { smoothingOn = false }
    }

    // MARK: – Peek / Pop helpers
    private func overlayQuickView() -> some View {
        Group {
            if let wrap = previewId,
               let cloth = vm.clothes.first(where: { $0.id == wrap.id }) {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                        .onTapGesture { previewId = nil }
                    ClothingQuickView(
                        imageURL: vm.imageSetsMap[cloth.id]?.first?.originalUrl,
                        name: cloth.name,
                        category: cloth.category,
                        color: cloth.color
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        commitId = cloth.id
                        previewId = nil
                    }
                }
                .zIndex(20)
                .animation(.spring(), value: previewId)
            }
        }
    }

    // MARK: – Utilities
    private func baseOffsetX(idx: Int, total: Int, width: CGFloat) -> CGFloat {
        let usable = width * (1 - 2*sideMargin)
        return width * sideMargin + usable * CGFloat(idx) / CGFloat(max(total-1,1))
    }

    private func bindingFor(id: UUID) -> Binding<Clothing>? {
        guard let i = vm.clothes.firstIndex(where: { $0.id == id }) else { return nil }
        return $vm.clothes[i]
    }

    private func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(max(v, lo), hi) }
}
