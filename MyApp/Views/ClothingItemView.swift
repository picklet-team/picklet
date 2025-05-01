import SwiftUI
import SDWebImageSwiftUI


struct ClothingItemView: View {
    let clothing: Clothing
    let imageUrl: String?

    var body: some View {
        VStack {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.5))
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                placeholderView
            }
        }
        .frame(width: 100)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)
            .cornerRadius(8)
    }
}
