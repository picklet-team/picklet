import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject var viewModel: ClothingViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager
  @EnvironmentObject var brandManager: BrandManager
  @Environment(\.dismiss) var dismiss

  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  // 編集用の一時的なコピーを作成 - privateを削除してinternalに
  @State var editingClothing: Clothing

  // privateを削除してinternalにする
  @State var editingSets: [EditableImageSet] = []
  @State var selectedImageSet: EditableImageSet?
  @State var showPhotoPicker = false
  @State var showDeleteConfirm = false
  @State var isBackgroundLoading = false

  // 初期化時に編集用のコピーを作成
  init(
    clothing: Binding<Clothing>,
    openPhotoPickerOnAppear: Bool = false,
    canDelete: Bool = true,
    isNew: Bool = false
  ) {
    self._clothing = clothing
    self.openPhotoPickerOnAppear = openPhotoPickerOnAppear
    self.canDelete = canDelete
    self.isNew = isNew
    // 編集用の一時的なコピーを作成
    self._editingClothing = State(initialValue: clothing.wrappedValue)
  }

  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack(spacing: 0) {
          // 全てのフォーム項目を統一
          UnifiedClothingFormSection(
            clothing: $editingClothing,
            imageSets: $editingSets,
            isBackgroundLoading: isBackgroundLoading,
            onAddImage: { showPhotoPicker = true },
            onSelectImage: prepareImageForEditing
          )
        }
      }
      .dismissKeyboardOnTap()
      .navigationBarHidden(true)
      .safeAreaInset(edge: .top) {
        headerSection
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear(perform: setupInitialData)
    .sheet(isPresented: $showPhotoPicker) { photoPickerSheet }
    .sheet(item: $selectedImageSet) { maskEditorSheet($0) }
    .tint(themeManager.currentTheme.accentColor)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private var headerSection: some View {
    HStack {
      // キャンセルボタン
      Button("キャンセル") {
        // 何もしないでそのまま閉じる（元のデータは変更されない）
        dismiss()
      }
      .foregroundColor(themeManager.currentTheme.primaryColor)

      Spacer()

      Text(isNew ? "新規登録" : "編集")
        .font(.headline)
        .fontWeight(.semibold)

      Spacer()

      // 保存ボタン（右上に移動）
      Button(isNew ? "登録" : "保存") {
        saveChanges()
      }
      .foregroundColor(themeManager.currentTheme.primaryColor)
      .fontWeight(.semibold)
    }
    .padding()
    .background(.ultraThinMaterial)
  }

  private var photoPickerSheet: some View {
    CaptureOrLibraryView { image in
      addNewImageSet(image)
    }
    .environmentObject(themeManager)
  }

  private func maskEditorSheet(_ imageSet: EditableImageSet) -> some View {
    MaskEditorView(imageSet: bindingFor(imageSet))
      .environmentObject(themeManager)
      .onDisappear {
        updateImageCache()
      }
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }
}
