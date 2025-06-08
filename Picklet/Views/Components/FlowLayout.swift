import SwiftUI

struct FlowLayout: Layout {
  let spacing: CGFloat

  init(spacing: CGFloat = 8) {
    self.spacing = spacing
  }

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let containerWidth = proposal.width ?? 0
    var currentRowWidth: CGFloat = 0
    var totalHeight: CGFloat = 0
    var maxRowHeight: CGFloat = 0

    for subview in subviews {
      let subviewSize = subview.sizeThatFits(.unspecified)

      if currentRowWidth + subviewSize.width + spacing > containerWidth && currentRowWidth > 0 {
        // 新しい行
        totalHeight += maxRowHeight + spacing
        currentRowWidth = subviewSize.width
        maxRowHeight = subviewSize.height
      } else {
        // 同じ行
        if currentRowWidth > 0 {
          currentRowWidth += spacing
        }
        currentRowWidth += subviewSize.width
        maxRowHeight = max(maxRowHeight, subviewSize.height)
      }
    }

    totalHeight += maxRowHeight
    return CGSize(width: containerWidth, height: totalHeight)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var currentRowWidth: CGFloat = 0
    var currentY: CGFloat = bounds.minY
    var maxRowHeight: CGFloat = 0
    var currentRowSubviews: [(subview: LayoutSubview, size: CGSize)] = []

    for subview in subviews {
      let subviewSize = subview.sizeThatFits(.unspecified)

      if currentRowWidth + subviewSize.width + spacing > bounds.width && currentRowWidth > 0 {
        // 現在の行を配置
        placeRowSubviews(currentRowSubviews, at: currentY, in: bounds)

        // 新しい行
        currentY += maxRowHeight + spacing
        currentRowWidth = subviewSize.width
        maxRowHeight = subviewSize.height
        currentRowSubviews = [(subview, subviewSize)]
      } else {
        // 同じ行に追加
        if currentRowWidth > 0 {
          currentRowWidth += spacing
        }
        currentRowWidth += subviewSize.width
        maxRowHeight = max(maxRowHeight, subviewSize.height)
        currentRowSubviews.append((subview, subviewSize))
      }
    }

    // 最後の行を配置
    if !currentRowSubviews.isEmpty {
      placeRowSubviews(currentRowSubviews, at: currentY, in: bounds)
    }
  }

  private func placeRowSubviews(
    _ rowSubviews: [(subview: LayoutSubview, size: CGSize)],
    at y: CGFloat,
    in bounds: CGRect) {
    var currentX: CGFloat = bounds.minX

    for (subview, size) in rowSubviews {
      subview.place(at: CGPoint(x: currentX, y: y), proposal: ProposedViewSize(size))
      currentX += size.width + spacing
    }
  }
}
