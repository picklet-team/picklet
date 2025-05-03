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
        // URLをデバッグ出力
        let _ = print("🖼️ 画像表示リクエスト: \(urlStr)")
        
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) { phase in
          switch phase {
          case .success(let img): 
            let _ = print("✅ 画像読み込み成功: \(urlStr)")
            img.resizable().scaledToFit()
          case .failure(let error):
            let _ = print("❌ 画像読み込み失敗: \(urlStr) - エラー: \(error.localizedDescription)")
            Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
          case .empty:
            let _ = print("⏳ 画像読み込み中: \(urlStr)")
            ProgressView()
          @unknown default:
            ProgressView()
          }
        }
        .frame(width: 150, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
      } else {
        // URLが無効な場合
        let _ = print("⚠️ 画像URLなし")
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .overlay(
            Image(systemName: "photo")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
          )
          .frame(width: 150, height: 150)
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
