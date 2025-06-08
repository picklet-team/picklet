import SwiftUI

// MARK: - メインセクション

struct ClothingDetailHeaderSection: View {
  @Binding var clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var viewModel: ClothingViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // お気に入り度（タップで変更可能）- ラベルを削除
      InteractiveStarRatingView(rating: $clothing.favoriteRating)
        .onChange(of: clothing.favoriteRating) { _, newRating in
          // 更新日時を設定
          clothing.updatedAt = Date()

          // ViewModelの同期更新（UIのちらつきを防ぐ）
          if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
            viewModel.clothes[index] = clothing
          }

          // Swift 6対応の非同期処理
          let clothingCopy = clothing
          DispatchQueue.global(qos: .userInitiated).async {
            let success = SQLiteManager.shared.updateClothing(clothingCopy)
            DispatchQueue.main.async {
              if success {
                print("✅ お気に入り度更新成功: \(newRating)")
              } else {
                print("❌ お気に入り度更新失敗")
              }
            }
          }
        }

      // 購入価格（常に表示）
      HStack {
        Text("購入価格")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Spacer()

        if let price = clothing.purchasePrice {
          PriceDisplayView(price: price)
        } else {
          // 購入価格未設定の場合は"-"で表示
          HStack(spacing: 4) {
            Image(systemName: "yensign.circle")
              .foregroundColor(.gray)
              .font(.title2)

            Text("-")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.gray)
          }
        }
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(16)
  }
}

struct ClothingDetailInfoSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "info.circle.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("詳細")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      VStack(spacing: 12) {
        HStack {
          Image(systemName: "calendar")
            .foregroundColor(.blue)
            .frame(width: 20)
          Text("登録日")
            .font(.subheadline)
            .foregroundColor(.secondary)
          Spacer()
          Text(DateFormatter.shortDate.string(from: clothing.createdAt))
            .font(.subheadline)
            .fontWeight(.medium)
        }
      }
      .padding()
      .background(Color(.secondarySystemBackground))
      .cornerRadius(16)
    }
  }
}

struct ClothingCategorySection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "tag.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("カテゴリ")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      if !clothing.categoryIds.isEmpty {
        FlowLayout(spacing: 8) {
          ForEach(categoryManager.getCategoryNames(for: clothing.categoryIds), id: \.self) { category in
            CompactTagView(text: category, color: themeManager.currentTheme.primaryColor)
          }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      } else {
        HStack {
          Image(systemName: "tag.dashed")
            .foregroundColor(.secondary)
          Text("カテゴリ未設定")
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      }
    }
  }
}

struct ClothingBrandSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var brandManager: BrandManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.purple)
        Text("ブランド")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.purple)
      }

      if let brandId = clothing.brandId {
        CompactTagView(text: brandManager.getBrandName(for: brandId), color: .purple)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
      } else {
        HStack {
          Image(systemName: "star.dashed")
            .foregroundColor(.secondary)
          Text("ブランド未設定")
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
      }
    }
  }
}

struct ClothingColorSection: View {
  let clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "paintpalette.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
        Text("カラー")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(themeManager.currentTheme.primaryColor)
      }

      Group {
        if !clothing.colors.isEmpty {
          HStack(spacing: 12) {
            ForEach(clothing.colors.prefix(10), id: \.id) { colorData in
              Circle()
                .fill(Color(colorData.color))
                .frame(width: 36, height: 36)
                .overlay(
                  Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }

            if clothing.colors.count > 10 {
              Text("+\(clothing.colors.count - 10)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }

            Spacer()
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
        } else {
          HStack {
            Image(systemName: "circle.dashed")
              .foregroundColor(.secondary)
            Text("カラー未設定")
              .foregroundColor(.secondary)
            Spacer()
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .cornerRadius(16)
        }
      }
    }
  }
}

struct ClothingWearCountSection: View {
  @Binding var clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var viewModel: ClothingViewModel

  // 今日着用したかどうかを判定
  private var hasWornToday: Bool {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    return viewModel.wearHistories.contains { history in
      history.clothingId == clothing.id &&
        history.wornAt >= today &&
        history.wornAt < tomorrow
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      // チェックマーク（着用状態表示・タップで削除）
      Button {
        if hasWornToday {
          // 着用記録を削除
          viewModel.removeWearHistoryForToday(for: clothing.id)

          // @Bindingの値も同期
          if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
            clothing = viewModel.clothes[index]
          }
        }
      } label: {
        Image(systemName: hasWornToday ? "checkmark.circle.fill" : "circle")
          .font(.title)
          .foregroundColor(hasWornToday ? .green : .gray)
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(!hasWornToday) // 未着用時はタップ無効

      // 今日着る/着用取り消しボタン（状態によって切り替え）
      Button {
        if hasWornToday {
          // 今日の着用履歴を削除
          viewModel.removeWearHistoryForToday(for: clothing.id)
        } else {
          // 着用履歴を追加
          viewModel.addWearHistory(for: clothing.id)
        }

        // @Bindingの値も同期
        if let index = viewModel.clothes.firstIndex(where: { $0.id == clothing.id }) {
          clothing = viewModel.clothes[index]
        }
      } label: {
        HStack {
          Image(systemName: hasWornToday ? "xmark.circle.fill" : "plus.circle.fill")
            .font(.title2)
            .foregroundColor(.white)

          Text(hasWornToday ? "着用取り消し" : "今日着る")
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.white)

          Spacer()
        }
        .padding()
        .background(hasWornToday ? Color.red : themeManager.currentTheme.primaryColor)
        .cornerRadius(16)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding(.vertical, 8)
  }
}
