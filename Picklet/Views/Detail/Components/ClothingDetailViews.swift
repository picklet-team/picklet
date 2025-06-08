import SwiftUI

// MARK: - 基本的な視覚コンポーネント

struct InteractiveStarRatingView: View {
  @Binding var rating: Int
  let maxRating: Int = 5

  var body: some View {
    HStack(spacing: 4) {
      ForEach(1 ... maxRating, id: \.self) { index in
        Button {
          rating = index
        } label: {
          Image(systemName: index <= rating ? "star.fill" : "star")
            .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
            .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }
}

struct StarRatingView: View {
  let rating: Int
  let maxRating: Int = 5

  var body: some View {
    HStack(spacing: 4) {
      ForEach(1 ... maxRating, id: \.self) { index in
        Image(systemName: index <= rating ? "star.fill" : "star")
          .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
          .font(.title3)
      }
    }
  }
}

struct PriceDisplayView: View {
  let price: Double

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "yensign.circle.fill")
        .foregroundColor(.green)
        .font(.title2)

      Text("¥\(Int(price).formatted())")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
    }
  }
}

struct CompactTagView: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(color.opacity(0.15))
      .foregroundColor(color)
      .cornerRadius(16)
  }
}

extension DateFormatter {
  static let shortDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
  }()
}
