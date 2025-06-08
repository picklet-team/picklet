import SDWebImageSwiftUI
import SwiftUI

struct ClothingDetailView: View {
  @EnvironmentObject var viewModel: ClothingViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager
  @EnvironmentObject var brandManager: BrandManager
  @Environment(\.dismiss) private var dismiss

  @Binding var clothing: Clothing
  let clothingId: UUID

  @State private var showEdit = false
  @State private var showDeleteConfirm = false

  var body: some View {
    ZStack {
      // 背景グラデーション
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      mainContent
    }
    .accessibility(identifier: "clothingDetailView")
    .navigationTitle(clothing.name)
    .navigationBarTitleDisplayMode(.large)
    .navigationBarBackButtonHidden(false)
    .tint(themeManager.currentTheme.accentColor)
    .sheet(isPresented: $showEdit) {
      ClothingEditView(
        clothing: $clothing,
        openPhotoPickerOnAppear: false,
        canDelete: true,
        isNew: false)
        .environmentObject(viewModel)
        .environmentObject(themeManager)
        .environmentObject(categoryManager)
        .environmentObject(brandManager)
    }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      Button("削除", role: .destructive) {
        deleteClothing()
      }
      Button("キャンセル", role: .cancel) {}
    }
    .onChange(of: viewModel.clothes) { _, newClothes in
      if !newClothes.contains(where: { $0.id == clothingId }) {
        dismiss()
      }
    }
  }

  // MARK: - メインコンテンツ

  private var mainContent: some View {
    VStack(spacing: 0) {
      scrollContent
      editButton
    }
  }

  // MARK: - スクロールコンテンツ

  private var scrollContent: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        // 画像ギャラリー
        ClothingImageGalleryView(
          imageSets: viewModel.imageSetsMap[clothingId] ?? [],
          showAddButton: false)

        // 詳細情報セクション
        detailInfoSection

        // カテゴリ・ブランド情報
        categoryBrandSection

        // カラー情報
        colorSection

        // 統計情報
        statisticsSection

        // アクション
        actionSection

        // スクロール領域の末尾に余白
        Spacer(minLength: 100)
      }
      .padding(.horizontal)
    }
  }

  // MARK: - 詳細情報セクション

  private var detailInfoSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("詳細情報")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      detailInfoContent
    }
  }

  private var detailInfoContent: some View {
    VStack(spacing: 12) {
      // 購入価格
      if let price = clothing.purchasePrice {
        DetailRowView(
          icon: "yensign.circle.fill",
          title: "購入価格",
          value: "¥\(Int(price).formatted())",
          color: .green)
      }

      // お気に入り度
      DetailRowView(
        icon: "star.fill",
        title: "お気に入り度",
        value: "\(clothing.favoriteRating)/5",
        color: .yellow)

      // 登録日
      DetailRowView(
        icon: "calendar",
        title: "登録日",
        value: DateFormatter.shortDate.string(from: clothing.createdAt),
        color: .blue)

      // 最終更新
      if clothing.updatedAt != clothing.createdAt {
        DetailRowView(
          icon: "clock",
          title: "最終更新",
          value: DateFormatter.shortDate.string(from: clothing.updatedAt),
          color: .orange)
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }

  // MARK: - カテゴリ・ブランドセクション

  private var categoryBrandSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("分類")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      categoryBrandContent
    }
  }

  private var categoryBrandContent: some View {
    VStack(spacing: 12) {
      // カテゴリ
      if !clothing.categoryIds.isEmpty {
        TagDisplayView(
          icon: "tag.fill",
          title: "カテゴリ",
          tags: categoryManager.getCategoryNames(for: clothing.categoryIds),
          color: themeManager.currentTheme.primaryColor)
      }

      // ブランド
      if let brandId = clothing.brandId {
        TagDisplayView(
          icon: "star.fill",
          title: "ブランド",
          tags: [brandManager.getBrandName(for: brandId)],
          color: .purple)
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }

  // MARK: - カラーセクション

  private var colorSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("カラー")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      colorContent
    }
  }

  private var colorContent: some View {
    Group {
      if !clothing.colors.isEmpty {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
          ForEach(clothing.colors, id: \.id) { colorData in
            Circle()
              .fill(Color(colorData.color))
              .frame(width: 40, height: 40)
              .overlay(
                Circle()
                  .stroke(Color.primary.opacity(0.2), lineWidth: 1))
              .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
          }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
      } else {
        Text("カラー未設定")
          .foregroundColor(.secondary)
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(12)
      }
    }
  }

  // MARK: - 統計セクション

  private var statisticsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("統計")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      statisticsContent
    }
  }

  private var statisticsContent: some View {
    VStack(spacing: 12) {
      // 登録からの日数
      let daysSinceCreation = Calendar.current.dateComponents([.day], from: clothing.createdAt, to: Date()).day ?? 0

      DetailRowView(
        icon: "calendar.badge.clock",
        title: "登録からの日数",
        value: "\(daysSinceCreation)日",
        color: .indigo)

      // 写真枚数
      let imageCount = viewModel.imageSetsMap[clothingId]?.count ?? 0
      DetailRowView(
        icon: "photo",
        title: "写真枚数",
        value: "\(imageCount)枚",
        color: .cyan)

      // 1日あたりコスト（購入価格がある場合）
      if let price = clothing.purchasePrice, daysSinceCreation > 0 {
        let costPerDay = price / Double(daysSinceCreation)
        DetailRowView(
          icon: "chart.line.uptrend.xyaxis",
          title: "1日あたりコスト",
          value: "¥\(Int(costPerDay))",
          color: .mint)
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }

  // MARK: - アクションセクション

  private var actionSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("アクション")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(themeManager.currentTheme.primaryColor)

      actionContent
    }
  }

  private var actionContent: some View {
    VStack(spacing: 12) {
      // お気に入り切り替え
      ActionRowView(
        icon: clothing.favoriteRating >= 4 ? "heart.fill" : "heart",
        title: clothing.favoriteRating >= 4 ? "お気に入りから削除" : "お気に入りに追加",
        color: .red) {
          toggleFavorite()
        }

      // 複製
      ActionRowView(
        icon: "doc.on.doc",
        title: "この衣類を複製",
        color: .blue) {
          duplicateClothing()
        }

      // 削除
      ActionRowView(
        icon: "trash",
        title: "削除",
        color: .red) {
          showDeleteConfirm = true
        }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
  }

  // MARK: - 編集ボタン

  private var editButton: some View {
    PrimaryActionButton(title: "編集する") {
      showEdit = true
    }
    .padding(.vertical, 8)
    .padding(.horizontal)
  }

  // MARK: - アクション関数

  private func toggleFavorite() {
    clothing.favoriteRating = clothing.favoriteRating >= 4 ? 3 : 5
    // ViewModelの更新は不要（Bindingで自動反映）
  }

  private func duplicateClothing() {
    let newClothing = Clothing(
      name: "\(clothing.name) のコピー",
      purchasePrice: clothing.purchasePrice,
      favoriteRating: clothing.favoriteRating,
      colors: clothing.colors,
      categoryIds: clothing.categoryIds,
      brandId: clothing.brandId,
      tagIds: clothing.tagIds)

    viewModel.addClothing(newClothing, imageSets: [])
  }

  private func deleteClothing() {
    viewModel.deleteClothing(clothing)
    dismiss()
  }
}

// MARK: - サポートビュー

struct DetailRowView: View {
  let icon: String
  let title: String
  let value: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundColor(color)
        .frame(width: 20)

      Text(title)
        .foregroundColor(.primary)

      Spacer()

      Text(value)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
    }
  }
}

struct TagDisplayView: View {
  let icon: String
  let title: String
  let tags: [String]
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(color)
        Text(title)
          .fontWeight(.medium)
      }

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
        ForEach(tags, id: \.self) { tag in
          Text(tag)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
      }
    }
  }
}

struct ActionRowView: View {
  let icon: String
  let title: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .foregroundColor(color)
          .frame(width: 20)

        Text(title)
          .foregroundColor(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
          .font(.caption)
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
  static let shortDate: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
  }()
}
