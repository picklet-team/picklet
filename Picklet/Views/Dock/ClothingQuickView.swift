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
  let clothingId: UUID?

  @State private var localImage: UIImage?
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager

  // 今日着用済みかどうかを判定する計算プロパティ
  private var isWornToday: Bool {
    guard let id = clothingId else { return false }
    return viewModel.isWornToday(for: id) // メソッド呼び出しに修正
  }

  var body: some View {
    VStack(spacing: 12) {
      // 画像表示部分（サイズを大きく）
      ZStack(alignment: .topTrailing) { // topTrailingで右上に配置
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
          .frame(width: 120, height: 120)
          .background(themeManager.currentTheme.lightBackgroundColor)
          .cornerRadius(12)
        } else if let image = localImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .background(themeManager.currentTheme.lightBackgroundColor)
            .cornerRadius(12)
        } else {
          Rectangle()
            .fill(themeManager.currentTheme.lightBackgroundColor)
            .overlay(
              Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundColor(.secondary))
            .frame(width: 120, height: 120)
            .cornerRadius(12)
        }

        // 今日着用済みの場合、画像の右上端にチェックマークを表示
        if isWornToday {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20))
            .foregroundColor(.white)
            .background(
              Circle()
                .fill(themeManager.currentTheme.primaryColor)
                .frame(width: 24, height: 24)
            )
            .offset(x: 4, y: -4) // 画像の枠内に収まるように微調整
        }
      }

      // 着用統計情報（以下は変更なし）
      if let id = clothingId {
        VStack(spacing: 8) {
          // 着用回数と単価の情報カード
          VStack(spacing: 6) {
            HStack {
              Text("着用回数")
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
              Text("\(viewModel.getWearCount(for: id))回")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryColor)
            }

            if let costPerWear = viewModel.getCostPerWear(for: id) {
              HStack {
                Text("着用単価")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Spacer()
                Text("¥\(Int(costPerWear))")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.green)
              }
            }

            if let lastWorn = viewModel.getLastWornDate(for: id) {
              let daysSince = Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day ?? 0
              HStack {
                Text("経過日数")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Spacer()
                Text("\(daysSince)日前")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(daysSince > 30 ? .orange : .secondary)
              }
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(width: 120)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
              .stroke(Color(.systemGray4), lineWidth: 0.5)
          )

          // 今日着る/着用取り消しボタン（状態によって切り替え）
          Button {
            if isWornToday {
              // 今日の着用履歴を削除
              viewModel.removeWearHistoryForToday(for: id)
            } else {
              // 着用履歴を追加
              viewModel.addWearHistory(for: id)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          } label: {
            HStack(spacing: 6) {
              Image(systemName: isWornToday ? "xmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14))
              Text(isWornToday ? "着用取り消し" : "今日着る")
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(width: 120, height: 36)
            .background(isWornToday ? Color.red : themeManager.currentTheme.primaryColor)
            .cornerRadius(8)
          }
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    )
    .onAppear {
      if imageURL == nil, let id = clothingId {
        loadImage(for: id)
      }
    }
  }

  init(clothingId: UUID? = nil, imageURL: String?) {
    self.clothingId = clothingId
    self.imageURL = imageURL
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
