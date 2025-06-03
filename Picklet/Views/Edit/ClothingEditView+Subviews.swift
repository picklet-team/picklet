import SwiftUI

// MARK: - EditableImageSet Extension

extension EditableImageSet {
  var hasHighQuality: Bool {
    return original.size.width >= 100 && original.size.height >= 100
  }
}

// MARK: - Subviews

struct ImageListSection: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Binding var imageSets: [EditableImageSet]
  let addAction: () -> Void
  let selectAction: (EditableImageSet) -> Void
  let isLoading: Bool

  var body: some View {
    VStack(alignment: .leading) {
      if isLoading {
        loadingIndicator
      }

      ClothingImageGalleryView(
        imageSets: $imageSets,
        showAddButton: true,
        onSelectImage: selectAction,
        onAddButtonTap: addAction)
    }
  }

  private var loadingIndicator: some View {
    HStack {
      Spacer()
      Text("高品質データを準備中...")
        .font(.caption)
        .foregroundColor(.secondary)
      ProgressView()
        .scaleEffect(0.7)
        .tint(themeManager.currentTheme.primaryColor)
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

struct ClothingFormSection: View {
  @Binding var clothing: Clothing
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager
  @EnvironmentObject var brandManager: BrandManager // 追加

  // カテゴリ関連の状態変数
  @State private var showingQuickAddCategory = false
  @State private var quickCategoryName = ""

  // ブランド関連の状態変数
  @State private var showingQuickAddBrand = false
  @State private var quickBrandName = ""

  var body: some View {
    VStack(spacing: 20) {
      // 登録日表示（読み取り専用）
      registrationDateSection

      // 値段入力
      priceSection

      // お気に入り度
      favoriteRatingSection

      // 色選択
      colorSelectionSection

      // カテゴリ選択
      categorySelectionSection

      // ブランド選択
      brandSelectionSection // 追加
    }
    .padding(.horizontal)
  }

  // 登録日セクション（読み取り専用）
  private var registrationDateSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("登録日")
        .font(.headline)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      HStack {
        Image(systemName: "calendar")
          .foregroundColor(themeManager.currentTheme.primaryColor)

        Text(clothing.createdAt, style: .date)
          .font(.body)
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.tertiarySystemBackground))
      .cornerRadius(8)
    }
  }

  // 値段セクション
  private var priceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("購入価格")
        .font(.headline)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      HStack {
        Image(systemName: "yensign.circle")
          .foregroundColor(themeManager.currentTheme.primaryColor)

        TextField("例: 3000", value: $clothing.purchasePrice, format: .number)
          .keyboardType(.numberPad)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 1)
      )
    }
  }

  // お気に入り度セクション
  private var favoriteRatingSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("お気に入り度")
        .font(.headline)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      HStack(spacing: 8) {
        ForEach(1...5, id: \.self) { rating in
          Button(action: {
            clothing.favoriteRating = rating
          }) {
            Image(systemName: rating <= clothing.favoriteRating ? "star.fill" : "star")
              .font(.title2)
              .foregroundColor(rating <= clothing.favoriteRating ?
                themeManager.currentTheme.primaryColor : Color(.systemGray4))
          }
          .buttonStyle(PlainButtonStyle())
        }

        Spacer()

        Text("\(clothing.favoriteRating)/5")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
  }

  // 色選択セクション（HSVベース）
  private var colorSelectionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("色")
          .font(.headline)
          .foregroundColor(themeManager.currentTheme.primaryColor)

        Spacer()

        Text("\(clothing.colors.count)/3")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      // HSVグリッド
      colorGrid

      // 選択中の色を小さな丸で表示
      if !clothing.colors.isEmpty {
        HStack(spacing: 6) {
          ForEach(clothing.colors.indices, id: \.self) { index in
            Circle()
              .fill(clothing.colors[index].color)
              .frame(width: 16, height: 16)
              .overlay(
                Circle()
                  .stroke(Color(.systemGray4), lineWidth: 0.5)
              )
          }
        }
        .padding(.top, 4)
      }
    }
  }

  private var colorGrid: some View {
    VStack(spacing: 3) {
      ForEach(0..<4, id: \.self) { brightnessIndex in
        HStack(spacing: 3) {
          // モノクロ（4段階：白→黒）
          colorButton(hue: 0, saturation: 0, brightness: Double(3 - brightnessIndex) / 3.0)

          // 色相環（4段階のトーン）
          ForEach(0..<9, id: \.self) { hueIndex in
            let hue = switch hueIndex {
            case 0: 0.0      // 赤
            case 1: 0.08     // オレンジ
            case 2: 0.16     // 黄色
            case 3: 0.25     // 黄緑
            case 4: 0.33     // 緑
            case 5: 0.5      // 水色
            case 6: 0.66     // 青
            case 7: 0.75     // 紫
            case 8: 0.9      // ピンク
            default: 0.0
            }

            // トーン別の彩度と明度設定
            let (saturation, brightness) = switch brightnessIndex {
            case 0: (0.25, 0.95)  // ペールトーン（薄く淡い）
            case 1: (0.45, 0.85)  // ペールと中間の間（元気さを下げる）
            case 2: (0.75, 0.75)  // 中程度（鮮やかではなく適度に）
            case 3: (0.8, 0.55)   // ちょっと暗め
            default: (0.5, 0.7)
            }

            colorButton(hue: hue, saturation: saturation, brightness: brightness)
          }
        }
      }
    }
  }

  private func colorButton(hue: Double, saturation: Double, brightness: Double) -> some View {
    let colorData = ColorData(hue: hue, saturation: saturation, brightness: brightness)
    let isSelected = clothing.colors.contains { colorData in
      abs(colorData.hue - hue) < 0.01 &&
      abs(colorData.saturation - saturation) < 0.01 &&
      abs(colorData.brightness - brightness) < 0.01
    }
    let isMaxSelected = clothing.colors.count >= 3 && !isSelected

    return Button(action: {
      if isSelected {
        clothing.colors.removeAll { colorData in
          abs(colorData.hue - hue) < 0.01 &&
          abs(colorData.saturation - saturation) < 0.01 &&
          abs(colorData.brightness - brightness) < 0.01
        }
      } else if clothing.colors.count < 3 {
        clothing.colors.append(colorData)
      }
    }) {
      Rectangle()
        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
        .aspectRatio(1, contentMode: .fit) // 固定サイズから比率ベースに変更
        .overlay(
          Rectangle()
            .stroke(
              isSelected ? themeManager.currentTheme.primaryColor : Color.clear,
              lineWidth: isSelected ? 2 : 0
            )
        )
        .opacity(isMaxSelected ? 0.4 : 1.0)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isMaxSelected)
  }

  // 個別衣類編集画面でのカテゴリ選択
  private var categorySelectionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("カテゴリ")
          .font(.headline)
          .foregroundColor(themeManager.currentTheme.primaryColor)

        Spacer()

        // その場で新規カテゴリ作成（全体のマスターデータに追加）
        Button(action: { showingQuickAddCategory = true }) {
          Image(systemName: "plus.circle")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }

      // マスターデータから選択（チェックボックス形式）
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
        ForEach(categoryManager.categories) { category in
          categoryCheckboxRow(category: category)
        }
      }

      // 選択中カテゴリの確認表示
      if !clothing.categoryIds.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("選択中:")
            .font(.caption)
            .foregroundColor(.secondary)

          Text(categoryManager.getCategoryDisplayText(for: clothing.categoryIds))
            .font(.caption)
            .foregroundColor(themeManager.currentTheme.primaryColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.primaryColor.opacity(0.1))
            )
        }
      }
    }
    .alert("カテゴリを追加", isPresented: $showingQuickAddCategory) {
      TextField("カテゴリ名", text: $quickCategoryName)
      Button("追加") {
        // 全体のマスターデータに追加 & この衣類にも自動選択
        if categoryManager.addCategory(quickCategoryName) {
          // 新しく追加されたカテゴリを自動的に選択
          if let newCategory = categoryManager.categories.last {
            clothing.categoryIds.append(newCategory.id)
          }
          quickCategoryName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        quickCategoryName = ""
      }
    }
  }

  private func categoryCheckboxRow(category: Category) -> some View {
    let isSelected = clothing.categoryIds.contains(category.id)

    return Button(action: {
      if isSelected {
        // 選択解除: この衣類からカテゴリIDを削除
        clothing.categoryIds.removeAll { $0 == category.id }
      } else {
        // 選択: この衣類にカテゴリIDを追加
        clothing.categoryIds.append(category.id)
      }
    }) {
      HStack(spacing: 8) {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
          .foregroundColor(isSelected ? themeManager.currentTheme.primaryColor : .gray)
          .font(.system(size: 16))

        Text(category.name)
          .font(.system(size: 14))
          .foregroundColor(.primary)
          .multilineTextAlignment(.leading)

        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(isSelected ? themeManager.currentTheme.primaryColor.opacity(0.1) : Color(.systemGray6))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(isSelected ? themeManager.currentTheme.primaryColor : Color.clear, lineWidth: 1)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  // ブランド選択セクション
  private var brandSelectionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("ブランド")
          .font(.headline)
          .foregroundColor(themeManager.currentTheme.primaryColor)

        Spacer()

        // その場で新規ブランド作成
        Button(action: { showingQuickAddBrand = true }) {
          Image(systemName: "plus.circle")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }

      // ブランド選択メニュー
      Menu {
        Button("未選択") {
          clothing.brandId = nil
        }

        ForEach(brandManager.brands) { brand in
          Button(brand.name) {
            clothing.brandId = brand.id
          }
        }
      } label: {
        HStack {
          Image(systemName: "star")
            .foregroundColor(themeManager.currentTheme.primaryColor)

          Text(brandManager.getBrandName(for: clothing.brandId))
            .foregroundColor(.primary)

          Spacer()

          Image(systemName: "chevron.down")
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 1)
        )
      }
    }
    .alert("ブランドを追加", isPresented: $showingQuickAddBrand) {
      TextField("ブランド名", text: $quickBrandName)
      Button("追加") {
        if brandManager.addBrand(quickBrandName) {
          if let newBrand = brandManager.brands.last {
            clothing.brandId = newBrand.id
          }
          quickBrandName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        quickBrandName = ""
      }
    }
  }
}
