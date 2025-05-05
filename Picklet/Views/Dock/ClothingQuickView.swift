//
//  ClothingQuickView.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SDWebImageSwiftUI
import SwiftUI

struct ClothingQuickView: View {
  let imageURL: String?
  let name: String
  let category: String
  let color: String?

  var body: some View {
    VStack(spacing: 12) {
      if let urlStr = imageURL, let url = URL(string: urlStr) {
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) { phase in
          switch phase {
          case .success(let img):
            img.resizable().scaledToFit()
              .onAppear {
                print("✅ 画像読み込み成功: \(urlStr)")
              }
          case .failure(let error):
            Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
              .onAppear {
                print("❌ 画像読み込み失敗: \(urlStr) - エラー: \(error.localizedDescription)")
              }
          case .empty:
            ProgressView()
              .onAppear {
                print("⏳ 画像読み込み中: \(urlStr)")
              }
          @unknown default:
            ProgressView()
          }
        }
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
          print("🖼️ 画像表示リクエスト: \(urlStr)")
        }
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .overlay(
            Image(systemName: "photo")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
          )
          .frame(width: 150, height: 150)
          .cornerRadius(12)
          .onAppear {
            print("⚠️ 画像URLなし")
          }
      }
      Text(name).font(.headline)
      Text(category).font(.subheadline).foregroundColor(.secondary)
      if let colorValue = color {
        Text(colorValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
          .background(Color(.secondarySystemBackground)).cornerRadius(6)
      }
    }
    .padding(24)
  }
}
