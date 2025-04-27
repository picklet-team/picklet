import SwiftUI
import SDWebImageSwiftUI

struct ClothingItemView: View {
    let clothing: Clothing

    var body: some View {
        VStack {
            WebImage(url: URL(string: clothing.image_url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .indicator(.activity)
            .frame(height: 150)
            .clipped()
            .cornerRadius(8)

            Text(clothing.name)
                .font(.caption)
                .lineLimit(1)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
