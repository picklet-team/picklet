import SwiftUI

struct FlowLayout: Layout {
  let spacing: CGFloat

  init(spacing: CGFloat = 8) {
    self.spacing = spacing
  }

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing)
    return result.bounds
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()) {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing)
    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: bounds.minX + result.frames[index].minX,
          y: bounds.minY + result.frames[index].minY),
        proposal: ProposedViewSize(result.frames[index].size))
    }
  }
}

struct FlowResult {
  var bounds = CGSize.zero
  var frames: [CGRect] = []

  init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
    var origin = CGPoint.zero
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      if origin.x + size.width > maxWidth {
        origin.x = 0
        origin.y += rowHeight + spacing
        rowHeight = 0
      }

      frames.append(CGRect(origin: origin, size: size))
      origin.x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
    }

    bounds = CGSize(width: maxWidth, height: origin.y + rowHeight)
  }
}
