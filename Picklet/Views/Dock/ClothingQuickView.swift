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
  let clothingId: UUID?

  @State private var localImage: UIImage?
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var viewModel: ClothingViewModel

  var body: some View {
    VStack(spacing: 12) {
      if let urlStr = imageURL, let url = URL(string: urlStr) {
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) { phase in
          switch phase {
          case let .success(img):
            img.resizable().scaledToFit()
              .onAppear {
                print("✅ 画像読み込み成功: \(urlStr)")
              }
          case let .failure(error):
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
      } else if let image = localImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(width: 150, height: 150)
          .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
          .cornerRadius(12)
          .onAppear {
            print("🖼️ ローカル画像を表示中")
          }
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .overlay(
            Image(systemName: "photo")
              .font(.system(size: 40))
              .foregroundColor(.secondary))
          .frame(width: 150, height: 150)
          .cornerRadius(12)
          .onAppear {
            print("⚠️ 画像URLなし、ローカル画像も未設定")
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
    .onAppear {
      if imageURL == nil, let id = clothingId {
        loadImage(for: id)
      }
    }
  }

  init(clothingId: UUID? = nil, imageURL: String?, name: String, category: String, color: String?) {
    self.clothingId = clothingId
    self.imageURL = imageURL
    self.name = name
    self.category = category
    self.color = color
  }

  // ViewModelから画像をロードする
  private func loadImage(for clothingId: UUID) {
    Task {
      if let image = await viewModel.getImageForClothing(clothingId) {
        await MainActor.run {
          self.localImage = image
        }
      }
    }
  }
}
