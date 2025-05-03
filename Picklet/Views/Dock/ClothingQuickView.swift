//
//  ClothingQuickView.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI
import SDWebImageSwiftUI

struct ClothingQuickView: View {
  let imageURL: String?
  let name: String
  let category: String
  let color: String?

  var body: some View {
    VStack(spacing: 12) {
      if let urlStr = imageURL, let url = URL(string: urlStr) {
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) {
          phase in
          switch phase {
          case .success(let img): img.resizable().scaledToFit()
          case .failure(_):
            Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
          default: ProgressView()
          }
        }
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      }
      Text(name).font(.headline)
      Text(category).font(.subheadline).foregroundColor(.secondary)
      if let c = color {
        Text(c).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
          .background(Color(.secondarySystemBackground)).cornerRadius(6)
      }
    }
    .padding(24)
  }
}
