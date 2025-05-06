import SDWebImageSwiftUI
import SwiftUI

struct ClothingItemView: View {
  let clothing: Clothing
  let imageUrl: String?

  var body: some View {
    ClothingImageCard(imageURL: imageUrl)
      .onAppear {
        print("👕 ClothingItemView - clothing: \(clothing.id), imageUrl: \(imageUrl ?? "nil")")
      }
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
          .onAppear {
            print("🖼️ 有効なURLから画像を読み込み中: \(urlString)")
          }
      } else {
        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing))
          .overlay(
            Image(systemName: "tshirt")
              .font(.system(size: 50))
              .foregroundColor(.gray.opacity(0.5)))
          .onAppear {
            if let imageURL = imageURL {
              print("⚠️ 無効なURL: \(imageURL)")
            } else {
              print("⚠️ URLが設定されていません")
            }
          }
      }
    }
    .frame(width: 150, height: 150) // サイズを大きくする
    .clipped()
    .cornerRadius(15) // 角の丸みを若干大きく
    .background(
      RoundedRectangle(cornerRadius: 15)
        .fill(Color(.secondarySystemBackground)))
    .overlay(
      RoundedRectangle(cornerRadius: 15)
        .stroke(Color.primary.opacity(0.3), lineWidth: 2.0) // 線を太く、やや濃く
    )
    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3) // 影を強調
  }
}
