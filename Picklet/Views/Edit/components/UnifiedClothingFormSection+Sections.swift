import SwiftUI

// MARK: - Form Sections Extension

extension UnifiedClothingFormSection {
  // 画像セクション
  var imageSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("画像")

      if isBackgroundLoading {
        HStack {
          Text("高品質データを準備中...")
            .font(.caption)
            .foregroundColor(.secondary)
          ProgressView()
            .scaleEffect(0.7)
            .tint(themeManager.currentTheme.primaryColor)
        }
        .padding(.vertical, 4)
      }

      ClothingImageGalleryView(
        imageSets: $imageSets,
        showAddButton: true,
        onSelectImage: onSelectImage,
        onAddButtonTap: onAddImage)
    }
  }

  // 名前セクション
  var nameSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("名前")

      HStack(spacing: 12) {
        Image(systemName: "tag.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
          .font(.title2)

        TextField("服の名前を入力", text: $clothing.name)
          .font(.body)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(10)
      }
    }
  }

  // 値段セクション
  var priceSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("購入価格")

      HStack(spacing: 12) {
        Image(systemName: "yensign.circle.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
          .font(.title2)

        TextField("例: 3000", value: $clothing.purchasePrice, format: .number)
          .keyboardType(.numberPad)
          .font(.body)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(10)
      }
    }
  }

  // 色選択セクション
  var colorSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("色")
      ColorSelectionView(colors: $clothing.colors)
    }
  }

  // カテゴリ選択セクション
  var categorySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("カテゴリ")
      CategorySelectionView(categoryIds: $clothing.categoryIds)
    }
  }

  // ブランド選択セクション
  var brandSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("ブランド")

      Menu {
        Button("未選択") {
          clothing.brandId = nil
        }

        ForEach(referenceDataManager.brands) { brandData in
          Button(brandData.name) {
            clothing.brandId = brandData.id
          }
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "star.fill")
            .foregroundColor(themeManager.currentTheme.primaryColor)
            .font(.title2)

          Text(referenceDataManager.getBrandName(for: clothing.brandId))
            .foregroundColor(.primary)
            .font(.body)

          Spacer()

          Image(systemName: "chevron.down")
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
      }
    }
  }

  // 登録日表示セクション
  var registrationDateSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("登録日")

      HStack(spacing: 12) {
        Image(systemName: "calendar")
          .foregroundColor(themeManager.currentTheme.primaryColor)
          .font(.title2)

        Text(clothing.createdAt, style: .date)
          .font(.body)
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(10)
    }
  }

  // 着用上限セクション
  var wearLimitSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionTitle("着用上限")

      HStack(spacing: 12) {
        Image(systemName: "repeat.circle.fill")
          .foregroundColor(themeManager.currentTheme.primaryColor)
          .font(.title2)

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            TextField("上限回数", value: $clothing.wearLimit, format: .number)
              .keyboardType(.numberPad)
              .font(.body)
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(10)

            Button("未設定") {
              clothing.wearLimit = nil
            }
            .font(.caption)
            .foregroundColor(themeManager.currentTheme.primaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
          }

          if let wearLimit = clothing.wearLimit {
            Text("現在の着用回数: \(clothing.wearCount)/\(wearLimit)")
              .font(.caption)
              .foregroundColor(.secondary)
          } else {
            Text("現在の着用回数: \(clothing.wearCount)回")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }
}
