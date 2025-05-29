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
      // 画像表示部分（既存のコード）
      if let urlStr = imageURL, let url = URL(string: urlStr) {
        WebImage(url: url, options: [.queryMemoryData, .queryDiskDataSync, .refreshCached]) { phase in
          switch phase {
          case let .success(img):
            img.resizable().scaledToFit()
          case .failure:
            Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
          case .empty:
            ProgressView()
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
      }

      // 基本情報
      Text(name).font(.headline)
      Text(category).font(.subheadline).foregroundColor(.secondary)
      if let colorValue = color {
        Text(colorValue).font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
          .background(Color(.secondarySystemBackground)).cornerRadius(6)
      }

      // 着用統計情報（新規追加）
      if let id = clothingId {
        VStack(spacing: 8) {
          HStack {
            Text("着用回数:")
            Spacer()
            Text("\(viewModel.getWearCount(for: id))回")
              .fontWeight(.semibold)
          }

          if let lastWorn = viewModel.getLastWornDate(for: id) {
            HStack {
              Text("最後に着用:")
              Spacer()
              Text(lastWorn, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          if let costPerWear = viewModel.getCostPerWear(for: id) {
            HStack {
              Text("1回あたり単価:")
              Spacer()
              Text("¥\(Int(costPerWear))")
                .fontWeight(.semibold)
                .foregroundColor(.green)
            }
          }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)

        // 今日着るボタン（新規追加）
        Button { // actionクロージャを末尾クロージャとして記述（引数ラベルなし）
          viewModel.addWearHistory(for: id)
          // 触覚フィードバック
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: { // labelクロージャを明示的に引数ラベル `label:` を付けて記述
          HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("今日着る")
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(Color.blue)
          .cornerRadius(8)
        }
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

  private func loadImage(for clothingId: UUID) {
    Task {
      if let image = viewModel.getImageForClothing(clothingId) {
        await MainActor.run {
          self.localImage = image
        }
      }
    }
  }
}
