import SwiftUI

enum ThemeColor: String, CaseIterable, Identifiable {
  case blue
  case green
  case orange
  case red
  case purple
  case pink
  case indigo
  case teal
  case brown
  case mint

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .blue: return "ブルー"
    case .green: return "グリーン"
    case .orange: return "オレンジ"
    case .red: return "レッド"
    case .purple: return "パープル"
    case .pink: return "ピンク"
    case .indigo: return "インディゴ"
    case .teal: return "ティール"
    case .brown: return "ブラウン"
    case .mint: return "ミント"
    }
  }

  var primaryColor: Color {
    switch self {
    case .blue: return .blue
    case .green: return .green
    case .orange: return .orange
    case .red: return .red
    case .purple: return .purple
    case .pink: return .pink
    case .indigo: return .indigo
    case .teal: return .teal
    case .brown: return .brown
    case .mint: return .mint
    }
  }

  var accentColor: Color {
    primaryColor
  }

  var backgroundGradient: LinearGradient {
    LinearGradient(
      colors: [primaryColor.opacity(0.15), primaryColor.opacity(0.05)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing)
  }

  var lightBackgroundColor: Color {
    primaryColor.opacity(0.1)
  }
}

class ThemeManager: ObservableObject {
  @Published var currentTheme: ThemeColor

  init() {
    let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeColor.blue.rawValue
    currentTheme = ThemeColor(rawValue: savedTheme) ?? .blue
  }

  func setTheme(_ theme: ThemeColor) {
    currentTheme = theme
    UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
  }
}
