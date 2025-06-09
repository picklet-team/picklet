import SwiftUI

struct ReferenceDataManagementView: View {
  let dataType: ReferenceDataType

  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var referenceDataManager: ReferenceDataManager
  @EnvironmentObject var viewModel: ClothingViewModel
  @State private var editingDataId: UUID?

  private var filteredData: [ReferenceData] {
    return referenceDataManager.getData(for: dataType)
  }

  // デフォルトアイテムの定義（データタイプ別）
  private var defaultItems: [(emoji: String, name: String)] {
    switch dataType {
    case .category:
      return [
        ("👔", "シャツ"),
        ("👕", "Tシャツ"),
        ("👖", "ズボン"),
        ("👗", "スカート"),
        ("🧦", "靴下"),
        ("👒", "帽子"),
        ("👜", "バッグ")
      ]
    case .brand:
      return [
        ("🏷️", "ブランド")
      ]
    case .tag:
      return [
        ("🌞", "夏用"),
        ("❄️", "冬用"),
        ("💼", "仕事用"),
        ("🎉", "カジュアル"),
        ("🏃", "スポーツ"),
        ("🌙", "部屋着"),
        ("👑", "お気に入り")
      ]
    }
  }

  var body: some View {
    ZStack {
      // 背景グラデーション
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: 0) {
        List {
          Section {
            ForEach(filteredData) { data in
              ManagementRowView(
                icon: data.icon,
                iconColor: themeManager.currentTheme.primaryColor,
                name: data.name,
                linkedItemsCount: getLinkedItemsCount(for: data),
                isInitialEdit: editingDataId == data.id,
                onIconChange: { newIcon in
                  var updatedData = data
                  updatedData.icon = newIcon
                  _ = referenceDataManager.updateData(updatedData)
                },
                onNameChange: { newName in
                  var updatedData = data
                  updatedData.name = newName
                  _ = referenceDataManager.updateData(updatedData)
                  // 編集完了
                  if editingDataId == data.id {
                    editingDataId = nil
                  }
                },
                onDelete: {
                  _ = referenceDataManager.deleteData(data)
                }
              )
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
            }

            // プラスボタン
            Button(action: addNewItem) {
              HStack(spacing: 12) {
                ZStack {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.primaryColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                  Image(systemName: "plus")
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .font(.system(size: 18, weight: .semibold))
                }

                Text("新しい\(dataType.displayName)を追加")
                  .font(.body)
                  .fontWeight(.medium)
                  .foregroundColor(themeManager.currentTheme.primaryColor)

                Spacer()
              }
              .padding(.vertical, 12)
              .padding(.horizontal, 16)
              .background(Color(.secondarySystemBackground))
              .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
        }
        .background(.clear)
        .scrollContentBackground(.hidden)
        .listStyle(PlainListStyle())
        .listRowSpacing(8)
      }
    }
    .navigationTitle("\(dataType.displayName)管理")
    .navigationBarTitleDisplayMode(.large)
    .keyboardOverlay()
  }

  private func addNewItem() {
    let randomItem = defaultItems.randomElement() ?? ("📁", "新しいアイテム")

    // ReferenceDataManagerのaddDataメソッドを使用
    _ = referenceDataManager.addData(
      type: dataType,
      name: randomItem.name,
      icon: randomItem.emoji
    )

    // 最後に追加されたアイテムのIDを取得して編集状態にする
    let latestData = referenceDataManager.getData(for: dataType).last
    if let latestId = latestData?.id {
      editingDataId = latestId
    }
  }

  private func getLinkedItemsCount(for data: ReferenceData) -> Int {
    switch data.type {
    case .category:
      return viewModel.clothes.filter { $0.categoryIds.contains(data.id) }.count
    case .brand:
      return viewModel.clothes.filter { $0.brandId == data.id }.count
    case .tag:
      return viewModel.clothes.filter { $0.tagIds.contains(data.id) }.count
    }
  }
}
