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

extension DateFormatter {
  static let detailViewShortDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
  }()
}
