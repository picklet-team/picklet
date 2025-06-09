import SwiftUI

// MARK: - Unified Clothing Form Section

struct UnifiedClothingFormSection: View {
  @Binding var clothing: Clothing
  @Binding var imageSets: [EditableImageSet]
  let isBackgroundLoading: Bool
  let onAddImage: () -> Void
  let onSelectImage: (EditableImageSet) -> Void

  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager
  @EnvironmentObject var brandManager: BrandManager

  var body: some View {
    VStack(spacing: 24) {
      // 画像セクション
      sectionCard {
        imageSection
      }

      // 名前セクション
      sectionCard {
        nameSection
      }

      // 値段セクション
      sectionCard {
        priceSection
      }

      // 色選択セクション
      sectionCard {
        colorSection
      }

      // カテゴリ選択セクション
      sectionCard {
        categorySection
      }

      // ブランド選択セクション
      sectionCard {
        brandSection
      }
      
      // 着用上限セクション
      sectionCard {
        wearLimitSection
      }

      // 登録日表示セクション
      sectionCard {
        registrationDateSection
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
  }

  // セクションカードのラッパー（統一）- internalに変更
  func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemBackground))
          .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color(.systemGray5), lineWidth: 1))
  }

  // セクションタイトル（統一）- internalに変更
  func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.headline)
      .fontWeight(.semibold)
      .foregroundColor(themeManager.currentTheme.primaryColor)
  }
}
