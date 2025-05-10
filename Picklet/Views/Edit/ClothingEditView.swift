import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @Environment(\.dismiss) private var dismiss
  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  @State private var editingSets: [EditableImageSet] = []
  @State private var selectedImageSet: EditableImageSet?
  @State private var showPhotoPicker = false
  @State private var showDeleteConfirm = false
  @State private var isBackgroundLoading = false

  // MARK: - View

  var body: some View {
    ZStack(alignment: .bottom) {
      mainContent
      saveButton
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear(perform: setupInitialData)
    .sheet(isPresented: $showPhotoPicker) { photoPickerSheet }
    .sheet(item: $selectedImageSet) { maskEditorSheet($0) }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      deleteConfirmationButtons
    }
  }

  // MARK: - View Components

  private var mainContent: some View {
    VStack(spacing: 0) {
      customHeader
      scrollableContent
    }
    .onTapGesture(perform: dismissKeyboard)
    .navigationBarHidden(true)
  }

  private var customHeader: some View {
    VStack {
      TextField("名前", text: $clothing.name)
        .font(.title.weight(.bold))
        .padding(10)
        .cornerRadius(10)
        .multilineTextAlignment(.center)
        .overlay(
          Rectangle()
            .frame(height: 1)
            .padding(.horizontal, 40)
            .foregroundColor(Color.gray.opacity(0.3)),
          alignment: .bottom)
    }
    .background(Color(.systemBackground))
  }

  private var scrollableContent: some View {
    ScrollView {
      VStack {
        ImageListSection(
          imageSets: $editingSets,
          addAction: { showPhotoPicker = true },
          selectAction: prepareImageForEditing,
          isLoading: isBackgroundLoading)
          .padding(.top, 8)

        ClothingFormSection(
          clothing: $clothing,
          canDelete: canDelete,
          onDelete: { showDeleteConfirm = true })
      }
      .padding(.bottom, 80)
    }
  }

  private var saveButton: some View {
    VStack {
      PrimaryActionButton(title: "保存", action: saveChanges)
    }
    .padding(.horizontal)
    .padding(.bottom, 16)
  }

  private var photoPickerSheet: some View {
    CaptureOrLibraryView { image in
      addNewImageSet(image)
    }
  }

  private func maskEditorSheet(_ imageSet: EditableImageSet) -> some View {
    MaskEditorView(imageSet: bindingFor(imageSet))
      .onDisappear {
        updateImageCache()
      }
  }

  private var deleteConfirmationButtons: some View {
    Group {
      Button("削除する", role: .destructive) {
        Task { await deleteClothing() }
      }
      Button("キャンセル", role: .cancel) {}
    }
  }

  // MARK: - Action Handlers

  private func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil, from: nil, for: nil)
  }

  private func setupInitialData() {
    editingSets = viewModel.imageSetsMap[clothing.id] ?? []

    if !isNew && !editingSets.isEmpty {
      enhanceImagesInBackground()
    }

    if openPhotoPickerOnAppear {
      showPhotoPicker = true
    }
  }

  private func prepareImageForEditing(_ set: EditableImageSet) {
    if !set.isNew {
      ensureHighQualityImage(for: set) { updatedSet in
        selectedImageSet = updatedSet
      }
    } else {
      selectedImageSet = set
    }
  }

  private func addNewImageSet(_ image: UIImage) {
    let newSet = EditableImageSet(
      id: UUID(),
      original: image.normalized(),
      originalUrl: nil,
      mask: nil,
      maskUrl: nil,
      result: nil,
      resultUrl: nil,
      isNew: true)

    editingSets.append(newSet)
    updateImageCache()
  }

  private func updateImageCache() {
    viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
  }

  private func saveChanges() {
    Task {
      viewModel.saveClothing(clothing, imageSets: editingSets, isNew: isNew)
      dismiss()
    }
  }

  private func deleteClothing() async {
    viewModel.deleteClothing(clothing)
    dismiss()
  }

  // MARK: - Image Processing

  /// バックグラウンドで画像の高品質バージョンを取得
  private func enhanceImagesInBackground() {
    isBackgroundLoading = true

    Task(priority: .low) {
      defer { Task { await MainActor.run { isBackgroundLoading = false } } }

      // Use localStorageService directly instead of imageMetadataService
      let images = viewModel.localStorageService.loadImageMetadata(for: clothing.id)
      let localStorageService = viewModel.localStorageService

      for image in images {
        await tryUpdateLowQualityImage(image, using: localStorageService)
      }

      await MainActor.run {
        updateImageCache()
      }
    }
  }

  private func tryUpdateLowQualityImage(_ image: ClothingImage, using storageService: LocalStorageService) async {
    guard let idx = editingSets.firstIndex(where: { $0.id == image.id }) else { return }

    let currentSet = editingSets[idx]

    // 低品質画像のみ更新
    guard currentSet.original.size.width < 100 || currentSet.original.size.height < 100 else { return }
    guard let originalPath = image.originalLocalPath,
          let loadedImage = storageService.loadImage(from: originalPath)
    else { return }

    let updatedSet = createUpdatedImageSet(from: currentSet, with: loadedImage)

    await MainActor.run {
      if let stillIdx = editingSets.firstIndex(where: { $0.id == image.id }) {
        editingSets[stillIdx] = updatedSet
      }
    }
  }

  /// 特定の画像を高品質バージョンに確実に更新（マスク編集前など）
  private func ensureHighQualityImage(for set: EditableImageSet, completion: @escaping (EditableImageSet) -> Void) {
    // すでに十分な品質があれば、そのままコールバック
    if set.hasHighQuality {
      completion(set)
      return
    }

    Task {
      // ローカルストレージからの取得を試みる
      if let updatedSet = await tryLoadImageFromLocal(set) {
        await MainActor.run { completion(updatedSet) }
        return
      }

      // ネットワークからの取得を試みる
      if let urlString = set.originalUrl, let url = URL(string: urlString) {
        loadImageFromNetwork(set: set, url: url, completion: completion)
      } else {
        await MainActor.run { completion(set) }
      }
    }
  }

  private func tryLoadImageFromLocal(_ set: EditableImageSet) async -> EditableImageSet? {
    // Get image metadata directly from localStorageService
    let images = viewModel.localStorageService.loadImageMetadata(for: clothing.id)

    guard let image = images.first(where: { $0.id == set.id }),
          let originalPath = image.originalLocalPath,
          let loadedImage = viewModel.localStorageService.loadImage(from: originalPath)
    else {
      return nil
    }

    let updatedSet = createUpdatedImageSet(from: set, with: loadedImage)

    // 配列も更新
    await MainActor.run {
      if let idx = editingSets.firstIndex(where: { $0.id == set.id }) {
        editingSets[idx] = updatedSet
      }
    }

    return updatedSet
  }

  private func loadImageFromNetwork(set: EditableImageSet, url: URL, completion: @escaping (EditableImageSet) -> Void) {
    let options: SDWebImageOptions = [.highPriority, .retryFailed, .refreshCached]

    SDWebImageManager.shared.loadImage(
      with: url,
      options: options,
      progress: nil) { image, _, _, _, _, _ in
        if let downloadedImage = image {
          let updatedSet = self.createUpdatedImageSet(from: set, with: downloadedImage)

          // ローカルに保存
          if let savedPath = self.viewModel.localStorageService.saveImage(
            downloadedImage,
            id: set.id,
            type: "original") {
            print("💾 高品質画像をローカルに保存: \(savedPath)")
          }

          // 配列も更新
          if let idx = self.editingSets.firstIndex(where: { $0.id == set.id }) {
            DispatchQueue.main.async {
              self.editingSets[idx] = updatedSet
              completion(updatedSet)
            }
          } else {
            completion(updatedSet)
          }
        } else {
          completion(set) // 失敗したら元の画像を使用
        }
      }
  }

  // MARK: - Helpers

  private func createUpdatedImageSet(from set: EditableImageSet, with newImage: UIImage) -> EditableImageSet {
    return EditableImageSet(
      id: set.id,
      original: newImage,
      originalUrl: set.originalUrl,
      mask: set.mask,
      maskUrl: set.maskUrl,
      result: set.result,
      resultUrl: set.resultUrl,
      isNew: set.isNew)
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }
}

// MARK: - EditableImageSet Extension

extension EditableImageSet {
  var hasHighQuality: Bool {
    return original.size.width >= 100 && original.size.height >= 100
  }
}

// MARK: - Subviews

private struct ImageListSection: View {
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
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

private struct ClothingFormSection: View {
  @Binding var clothing: Clothing
  let canDelete: Bool
  let onDelete: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      VStack(alignment: .leading) {
        Text("服の情報")
          .font(.headline)
          .padding(.bottom, 4)

        VStack(spacing: 12) {
          TextField("カテゴリ", text: $clothing.category)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

          TextField("色", text: $clothing.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      if canDelete {
        deleteButton
      }
    }
  }

  private var deleteButton: some View {
    Section {
      Button(action: onDelete) {
        Text("削除")
          .font(.callout)
          .foregroundColor(.red.opacity(0.8))
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .listRowBackground(Color.clear)
    }
    .textCase(nil)
  }
}
