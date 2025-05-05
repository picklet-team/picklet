//
//  PhotoLibraryPickerView.swift
//  Picklet
//
//  Updated: keep the same item at the top when column count changes
//

import Photos
import SwiftUI

struct PhotoLibraryPickerView: View {
  let onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var assets: [PHAsset] = []
  private let imageManager = PHCachingImageManager()

  private var columnsCount: Int = 4
  private let spacing: CGFloat = 4

  /// イニシャライザ
  init(onImagePicked: @escaping (UIImage) -> Void) {
    self.onImagePicked = onImagePicked
  }

  var body: some View {
    NavigationView {
      GeometryReader { geo in
        let totalSpacing = spacing * CGFloat(columnsCount + 1)
        let cellSize = (geo.size.width - totalSpacing) / CGFloat(columnsCount)

        ScrollView {
          LazyVGrid(
            columns: Array(repeating: .init(.fixed(cellSize), spacing: spacing), count: columnsCount),
            spacing: spacing
          ) {
            ForEach(assets, id: \.localIdentifier) { asset in
              PhotoThumbnailCell(
                asset: asset,
                size: cellSize,
                manager: imageManager
              ) { image in
                let square = image.squareCropped()
                onImagePicked(square)
                dismiss()
              }
//                          .id(asset.localIdentifier)
//                          .background(
//                              GeometryReader { gp in
//                                  Color.clear.preference(
//                                      key: CellTopPreferenceKey.self,
//                                      value: [asset.localIdentifier: gp.frame(in: .named("gridSpace")).minY])
//                              }
//                          )
            }
          }
          .padding(spacing)
        }
        .accessibility(identifier: "photoLibraryPicker")
        .onAppear(perform: fetchAssets)
      }
      //            .navigationTitle("写真を選択")
    }
  }

  // MARK: - Scroll proxy holder

  @State private var scrollProxy: ScrollViewProxy?

  private func fetchAssets() {
    let opts = PHFetchOptions()
    opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let result = PHAsset.fetchAssets(with: .image, options: opts)
    var tmp: [PHAsset] = []
    result.enumerateObjects { obj, _, _ in tmp.append(obj) }
    assets = tmp
  }
}

// MARK: - Thumbnail Cell

struct PhotoThumbnailCell: View {
  let asset: PHAsset
  let size: CGFloat
  let manager: PHCachingImageManager
  let onSelect: (UIImage) -> Void

  @State private var thumbnail: UIImage?

  var body: some View {
    ZStack {
      if let thumb = thumbnail {
        Image(uiImage: thumb).resizable().scaledToFill()
      } else {
        Color.gray.opacity(0.2)
      }
    }
    .frame(width: size, height: size)
    .clipped()
    .cornerRadius(6)
    .onAppear(perform: loadThumb)
    .onTapGesture { requestFull() }
  }

  private func loadThumb() {
    let opts = PHImageRequestOptions()
    opts.deliveryMode = .highQualityFormat
    opts.resizeMode = .exact
    let target = CGSize(width: size * UIScreen.main.scale, height: size * UIScreen.main.scale)
    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFill, options: opts) { img, _ in
      thumbnail = img
    }
  }

  private func requestFull() {
    let opts = PHImageRequestOptions()
    opts.deliveryMode = .highQualityFormat
    opts.resizeMode = .exact
    opts.isNetworkAccessAllowed = true
    let target = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: opts) { img, _ in
      if let img = img { onSelect(img) }
    }
  }
}
