import SwiftUI
import SDWebImageSwiftUI

struct ClothingItemView: View {
    @EnvironmentObject var viewModel: ClothingViewModel
    let clothing: Clothing

    var body: some View {
        VStack {
          if let firstImageUrl = viewModel.clothingImages[clothing.id]?.first?.image_url,
             let url = URL(string: firstImageUrl) {
              WebImage(url: url)
                  .resizable()
                  .scaledToFill()
                  .frame(height: 150)
                  .clipped()
                  .cornerRadius(8)
          } else {
              Color.gray
                  .frame(height: 150)
                  .cornerRadius(8)
          }

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
