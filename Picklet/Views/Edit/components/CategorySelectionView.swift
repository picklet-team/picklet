import SwiftUI

// MARK: - カテゴリ選択を独立したViewに分離
struct CategorySelectionView: View {
  @Binding var categoryIds: [UUID]
  @EnvironmentObject var categoryManager: CategoryManager
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(spacing: 16) {
      // 選択状況の表示
      HStack {
        Text("\(categoryIds.count)個選択中")
          .font(.caption)
          .foregroundColor(.secondary)
        
        Spacer()
        
        if !categoryIds.isEmpty {
          Button("すべて解除") {
            categoryIds.removeAll()
          }
          .font(.caption)
          .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }

      // カテゴリグリッド
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 12) {
        ForEach(categoryManager.categories) { category in
          CategoryChip(
            category: category,
            categoryIds: $categoryIds,
            themeManager: themeManager
          )
        }
      }
    }
  }
}

// MARK: - カテゴリチップ（改良版）
struct CategoryChip: View {
  let category: Category
  @Binding var categoryIds: [UUID]
  let themeManager: ThemeManager
  @State private var isPressed = false

  private var isSelected: Bool {
    categoryIds.contains(category.id)
  }

  var body: some View {
    Button(action: toggleCategory) {
      HStack(spacing: 8) {
        Text(category.name)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(isSelected ? .white : .primary)
          .lineLimit(1)

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 22)
          .fill(isSelected ? 
            themeManager.currentTheme.primaryColor : 
            Color(.secondarySystemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 22)
          .stroke(
            isSelected ? 
              Color.clear : 
              themeManager.currentTheme.primaryColor.opacity(0.3),
            lineWidth: 1.5
          )
      )
      .scaleEffect(isPressed ? 0.95 : 1.0)
    }
    .buttonStyle(PlainButtonStyle())
    .animation(.easeInOut(duration: 0.15), value: isPressed)
    .animation(.easeInOut(duration: 0.2), value: isSelected)
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
      isPressed = pressing
    }, perform: {})
  }

  private func toggleCategory() {
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    
    withAnimation(.easeInOut(duration: 0.2)) {
      if isSelected {
        categoryIds.removeAll { $0 == category.id }
      } else {
        categoryIds.append(category.id)
      }
    }
  }
}
