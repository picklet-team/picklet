import SwiftUI

// MARK: - 色選択を独立したViewに分離
struct ColorSelectionView: View {
  @Binding var colors: [ColorData]
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("\(colors.count)/3")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        // HSVグリッド
        colorGrid

        // 選択中の色を小さな丸で表示
        if !colors.isEmpty {
          selectedColorsDisplay
        }
      }
    }
  }

  private var selectedColorsDisplay: some View {
    HStack(spacing: 6) {
      ForEach(colors.indices, id: \.self) { index in
        Circle()
          .fill(colors[index].color)
          .frame(width: 16, height: 16)
          .overlay(
            Circle()
              .stroke(Color(.systemGray4), lineWidth: 0.5))
      }
    }
    .padding(.top, 4)
  }

  private var colorGrid: some View {
    VStack(spacing: 3) {
      ForEach(0..<4, id: \.self) { brightnessIndex in
        HStack(spacing: 3) {
          // モノクロ（4段階：白→黒）
          OptimizedColorButton(
            hue: 0, saturation: 0,
            brightness: Double(3 - brightnessIndex) / 3.0,
            colors: $colors,
            themeManager: themeManager
          )

          // 色相環（4段階のトーン）
          ForEach(0..<9, id: \.self) { hueIndex in
            let hue = getHue(for: hueIndex)
            let (saturation, brightness) = getToneValues(for: brightnessIndex)

            OptimizedColorButton(
              hue: hue, saturation: saturation, brightness: brightness,
              colors: $colors,
              themeManager: themeManager
            )
          }
        }
      }
    }
  }

  private func getHue(for index: Int) -> Double {
    switch index {
    case 0: return 0.0    // 赤
    case 1: return 0.08   // オレンジ
    case 2: return 0.16   // 黄色
    case 3: return 0.25   // 黄緑
    case 4: return 0.33   // 緑
    case 5: return 0.5    // 水色
    case 6: return 0.66   // 青
    case 7: return 0.75   // 紫
    case 8: return 0.9    // ピンク
    default: return 0.0
    }
  }

  private func getToneValues(for brightnessIndex: Int) -> (Double, Double) {
    switch brightnessIndex {
    case 0: return (0.25, 0.95) // ペールトーン
    case 1: return (0.45, 0.85) // ペールと中間の間
    case 2: return (0.75, 0.75) // 中程度
    case 3: return (0.8, 0.55)  // ちょっと暗め
    default: return (0.5, 0.7)
    }
  }
}

// MARK: - 最適化されたカラーボタン
struct OptimizedColorButton: View {
  let hue: Double
  let saturation: Double
  let brightness: Double
  @Binding var colors: [ColorData]
  let themeManager: ThemeManager

  // パフォーマンス最適化: 計算済みの値をプロパティとして保持
  private var colorData: ColorData {
    ColorData(hue: hue, saturation: saturation, brightness: brightness)
  }

  private var isSelected: Bool {
    colors.contains { existingColor in
      abs(existingColor.hue - hue) < 0.01 &&
      abs(existingColor.saturation - saturation) < 0.01 &&
      abs(existingColor.brightness - brightness) < 0.01
    }
  }

  private var isMaxSelected: Bool {
    colors.count >= 3 && !isSelected
  }

  var body: some View {
    Button(action: toggleColor) {
      Rectangle()
        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
        .aspectRatio(1, contentMode: .fit)
        .overlay(
          Rectangle()
            .stroke(
              isSelected ? themeManager.currentTheme.primaryColor : Color.clear,
              lineWidth: isSelected ? 2 : 0))
        .opacity(isMaxSelected ? 0.4 : 1.0)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isMaxSelected)
  }

  private func toggleColor() {
    if isSelected {
      colors.removeAll { existingColor in
        abs(existingColor.hue - hue) < 0.01 &&
        abs(existingColor.saturation - saturation) < 0.01 &&
        abs(existingColor.brightness - brightness) < 0.01
      }
    } else if colors.count < 3 {
      colors.append(colorData)
    }
  }
}
