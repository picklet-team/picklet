//
//  GlobalOverlayView.swift
//  Picklet
//
//  Created on 2025/05/07.
//

import SwiftUI

// 全画面オーバーレイを表示するためのEnvironmentKey
struct OverlayPresentationKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// オーバーレイの背景色用のEnvironmentKey
struct OverlayBackgroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .black.opacity(0.5)
}

// 環境変数拡張
extension EnvironmentValues {
    var isOverlayPresented: Bool {
        get { self[OverlayPresentationKey.self] }
        set { self[OverlayPresentationKey.self] = newValue }
    }

    var overlayBackgroundColor: Color {
        get { self[OverlayBackgroundColorKey.self] }
        set { self[OverlayBackgroundColorKey.self] = newValue }
    }
}

// 全画面オーバーレイビュー
struct FullScreenOverlay<OverlayContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let overlayColor: Color
    let content: () -> OverlayContent

    // ViewModifierのbodyメソッドでは引数名をbaseContentなど、contentと異なる名前にする必要がある
    func body(content baseContent: Content) -> some View {
        ZStack {
            baseContent
                .disabled(isPresented)

            if isPresented {
                overlayColor
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)

                self.content()
                    // ズームインではなく、シンプルにフェードイン
                    .transition(.opacity)
                    // 少しだけ小さく開始して自然な印象に
                    .scaleEffect(isPresented ? 1.0 : 0.97)
                    // パッと表示されるように高速なアニメーション
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPresented)
            }
        }
        // 全体のアニメーション速度を上げる
        .animation(.easeOut(duration: 0.15), value: isPresented)
        .environment(\.isOverlayPresented, isPresented)
    }
}

// 使いやすいように拡張メソッドを提供
extension View {
    func fullScreenOverlay<Content: View>(
        isPresented: Binding<Bool>,
        overlayColor: Color = .black.opacity(0.5),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(FullScreenOverlay(
            isPresented: isPresented,
            overlayColor: overlayColor,
            content: content
        ))
    }
}

// アプリ全体で使用するためのオーバーレイ管理クラス
class GlobalOverlayManager: ObservableObject {
    @Published var isPresented = false
    @Published var overlayView: AnyView? = nil
    @Published var backgroundColor: Color = .black.opacity(0.5)

    func present<Content: View>(_ content: Content, backgroundColor: Color = .black.opacity(0.5)) {
        self.overlayView = AnyView(content)
        self.backgroundColor = backgroundColor
        withAnimation(.easeOut(duration: 0.15)) {
            self.isPresented = true
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) {
            self.isPresented = false
        }
    }
}

// 実際にアプリ全体に適用するオーバーレイビュー
struct GlobalOverlayContainerView<Content: View>: View {
    @StateObject private var overlayManager = GlobalOverlayManager()
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .disabled(overlayManager.isPresented)
                .environmentObject(overlayManager)

            if overlayManager.isPresented, let overlayContent = overlayManager.overlayView {
                Color.black
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea(.all) // 確実に全画面をカバー
                    .onTapGesture {
                        overlayManager.dismiss()
                    }
                    .transition(.opacity)

                overlayContent
                    // ズームインではなく、シンプルにフェードイン
                    .transition(.opacity)
                    // 少しだけ小さく開始して自然な印象に
                    .scaleEffect(overlayManager.isPresented ? 1.0 : 0.97)
                    .zIndex(1000)
            }
        }
        // 全体のアニメーション速度を上げる
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: overlayManager.isPresented)
    }
}
