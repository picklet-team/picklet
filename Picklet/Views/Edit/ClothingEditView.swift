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

  // privateを削除してinternalにする
  @State var editingSets: [EditableImageSet] = []
  @State var selectedImageSet: EditableImageSet?
  @State var showPhotoPicker = false
  @State var showDeleteConfirm = false
  @State var isBackgroundLoading = false

  var body: some View {
    ZStack {
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: 0) {
        headerSection
        scrollableContent
        saveButtonSection
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear(perform: setupInitialData)
    .sheet(isPresented: $showPhotoPicker) { photoPickerSheet }
    .sheet(item: $selectedImageSet) { maskEditorSheet($0) }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      deleteConfirmationButtons
    }
    .tint(themeManager.currentTheme.accentColor)
  }

  private var headerSection: some View {
    HStack {
      // キャンセルボタン
      Button("キャンセル") {
        dismiss() // ViewModelは一切触らない
      }
      .foregroundColor(themeManager.currentTheme.primaryColor)

      Spacer()

      Text(isNew ? "新規登録" : "編集")
        .font(.headline)
        .fontWeight(.semibold)

      Spacer()

      // 削除ボタン（既存衣類のみ）
      if canDelete && !isNew {
        Button("削除") {
          showDeleteConfirm = true
        }
        .foregroundColor(.red)
      } else {
        Text("")
          .frame(width: 40)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
  }

  private var scrollableContent: some View {
    ScrollView {
      VStack(spacing: 16) {
        // 画像リスト
        ImageListSection(
          imageSets: $editingSets,
          addAction: { showPhotoPicker = true },
          selectAction: prepareImageForEditing,
          isLoading: isBackgroundLoading)
          .padding(.top, 8)

        // 名前編集セクション
        nameEditSection

        // その他のフォーム
        ClothingFormSection(clothing: $clothing)
      }
      .padding(.bottom, 100)
    }
  }

  private var nameEditSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("名前")
        .font(.headline)
        .foregroundColor(themeManager.currentTheme.primaryColor)
        .padding(.horizontal)

      TextField("服の名前を入力", text: $clothing.name)
        .font(.title3)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }
  }

  private var saveButtonSection: some View {
    PrimaryActionButton(title: isNew ? "登録する" : "保存する") {
      if isNew {
        viewModel.addClothing(clothing, imageSets: editingSets)
      } else {
        viewModel.updateClothing(clothing, imageSets: editingSets)
      }
      dismiss()
    }
    .padding(.horizontal)
    .padding(.bottom, 16)
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

  private var deleteConfirmationButtons: some View {
    Group {
      Button("削除する", role: .destructive) {
        viewModel.deleteClothing(clothing)
        dismiss()
      }
      Button("キャンセル", role: .cancel) {}
    }
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }
}
