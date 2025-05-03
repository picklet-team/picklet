import SDWebImageSwiftUI
import SwiftUI

struct ClothingItemView: View {
  let imageUrl: String?

  var body: some View {
    ClothingImageCard(imageURL: imageUrl)
  }
}

// Card component for image display
private struct ClothingImageCard: View {
  let imageURL: String?

  var body: some View {
    ZStack {
      if let urlString = imageURL, let url = URL(string: urlString) {
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
          .resizable()
          .indicator(.activity)
          .transition(.fade(duration: 0.5))
          .scaledToFill()
      } else {
        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            Image(systemName: "tshirt")
              .font(.system(size: 40))
              .foregroundColor(.gray.opacity(0.5))
          )
      }
    }
    .frame(width: 120, height: 120)
    .clipped()
    .cornerRadius(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.secondarySystemBackground))
    )
    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
  }
}
