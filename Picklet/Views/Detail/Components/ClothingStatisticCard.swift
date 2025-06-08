import SwiftUI

struct ImprovedStatisticCardView: View {
  let icon: String
  let value: String
  let label: String
  let color: Color
  let progress: Double?

  init(icon: String, value: String, label: String, color: Color, progress: Double? = nil) {
    self.icon = icon
    self.value = value
    self.label = label
    self.color = color
    self.progress = progress
  }

  var body: some View {
    VStack(spacing: 12) {
      // アイコンと値
      VStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(color.opacity(0.1))
            .frame(width: 50, height: 50)

          Image(systemName: icon)
            .font(.title2)
            .foregroundColor(color)
        }

        Text(value)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
          .minimumScaleFactor(0.8)
          .lineLimit(1)
      }

      // プログレスバー（オプション）
      if let progress = progress {
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(color.opacity(0.2))
              .frame(height: 4)
              .cornerRadius(2)

            Rectangle()
              .fill(color)
              .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
              .cornerRadius(2)
          }
        }
        .frame(height: 4)
      }

      // ラベル
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(16)
  }
}
