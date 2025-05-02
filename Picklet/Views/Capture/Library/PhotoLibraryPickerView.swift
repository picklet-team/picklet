//
//  PhotoLibraryPickerView.swift
//  MyApp
//
//  Updated: keep the same item at the top when column count changes
//

import Photos
import SwiftUI

// PreferenceKey to pass each cell's vertical position up the view tree
private struct CellTopPreferenceKey: PreferenceKey {
  static var defaultValue: [String: CGFloat] = [:]
  static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })
  }
}

struct PhotoLibraryPickerView: View {
  let onImagePicked: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  @State private var assets: [PHAsset] = []
  private let imageManager = PHCachingImageManager()

  @State private var columnsCount: Int = 4
  private let spacing: CGFloat = 4

  // id of the cell that was nearest to the top before layout change
  @State private var topVisibleId: String?

  var body: some View {
    NavigationView {
      GeometryReader { geo in
        let totalSpacing = spacing * CGFloat(columnsCount + 1)
        let cellSize = (geo.size.width - totalSpacing) / CGFloat(columnsCount)

        VStack(spacing: spacing) {
          //                    // Column selection buttons
          //                    HStack(spacing: spacing) {
          //                        ForEach([3,4,5,6,7], id: \.self) { count in
          //                            Button("\(count)列") {
          //                                // remember the current top cell id before changing layout
          //                                let currentTop = topVisibleId
          //                                withAnimation {
          //                                    columnsCount = count
          //                                }
          //                                // after slight delay (layout finished) scroll to saved id
          //                                if let id = currentTop {
          //                                    DispatchQueue.main.async {
          //                                        scrollProxy?.scrollTo(id, anchor: .top)
          //                                    }
          //                                }
          //                            }
          //                            .font(.subheadline)
          //                            .padding(.vertical,6)
          //                            .padding(.horizontal,12)
          //                            .background(columnsCount==count ? Color.accentColor.opacity(0.2):Color.clear)
          //                            .cornerRadius(6)
          //                        }
          //                    }
          //                    .padding(.horizontal, spacing)
          //
          //                    Divider()

          // Grid
          ScrollViewReader { proxy in
            ScrollView {
              LazyVGrid(
                columns: Array(
                  repeating: .init(.fixed(cellSize), spacing: spacing), count: columnsCount),
                spacing: spacing
              ) {
                ForEach(assets, id: \.localIdentifier) { asset in
                  PhotoThumbnailCell(asset: asset, size: cellSize, manager: imageManager) { image in
                    onImagePicked(image)
                    dismiss()
                  }
                  .id(asset.localIdentifier)
                  .background(
                    GeometryReader { gp in
                      Color.clear.preference(
                        key: CellTopPreferenceKey.self,
                        value: [asset.localIdentifier: gp.frame(in: .named("gridSpace")).minY])
                    }
                  )
                }
              }
              .padding(spacing)
            }
            .coordinateSpace(name: "gridSpace")
            .onPreferenceChange(CellTopPreferenceKey.self) { values in
              // find the smallest non‑negative Y (closest to top)
              if let (id, _) = values.filter({ $0.value >= 0 }).min(by: { $0.value < $1.value }) {
                topVisibleId = id
              }
            }
            // expose proxy to outer scope via capture list
            .onAppear { scrollProxy = proxy }
          }
        }
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
    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFill, options: opts) {
      img, _ in thumbnail = img
    }
  }

  private func requestFull() {
    let opts = PHImageRequestOptions()
    opts.deliveryMode = .highQualityFormat
    opts.resizeMode = .exact
    opts.isNetworkAccessAllowed = true
    let target = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    manager.requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: opts) {
      img, _ in if let img = img { onSelect(img) }
    }
  }
}
