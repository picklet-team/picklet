//
//  ImageView.swift
//  Picklet
//
//  Created by al dente on 2025/05/01.
//

import SDWebImageSwiftUI
import SwiftUI

struct DecoratedImage: View {
  let image: Image
  let size: CGFloat

  var body: some View {
    image
      .resizable()
      .aspectRatio(1, contentMode: .fill)
      .frame(width: size, height: size)
      .clipped()
      .cornerRadius(12)
      .shadow(radius: 4)
  }
}

struct ImageView: View {
  let image: UIImage?
  let urlStr: String?

  var body: some View {
    if let image = image {
      DecoratedImage(image: Image(uiImage: image), size: 300)
    } else if let urlStr = urlStr, let url = URL(string: urlStr) {
      WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) { phase in
        switch phase {
        case .empty:
          ProgressView()
        case .success(let image):
          DecoratedImage(image: image, size: 300)
        case .failure:
          Text("画像読み込み失敗")
        @unknown default:
          EmptyView()
        }
      }
    } else {
      Text("画像なし")
    }
  }
}
