//
//  MaskEditCanvasView.swift
//  MyApp
//
//  Created by al dente on 2025/04/28.
//


import SwiftUI

struct MaskEditCanvasView: UIViewRepresentable {
    @Binding var drawingImage: UIImage // ユーザーの描いたマスク
    var penColor: UIColor // 白=追加 / 黒=削除
    var penWidth: CGFloat = 20.0

    func makeUIView(context: Context) -> DrawingCanvas {
        let canvas = DrawingCanvas()
        canvas.isUserInteractionEnabled = true
        return canvas
    }

    func updateUIView(_ uiView: DrawingCanvas, context: Context) {
        uiView.penColor = penColor
        uiView.penWidth = penWidth
    }

    class DrawingCanvas: UIView {
        private var lines: [Line] = []
        var penColor: UIColor = .white
        var penWidth: CGFloat = 20.0

        private var lastPoint: CGPoint?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let point = touches.first?.location(in: self) {
                lastPoint = point
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let point = touches.first?.location(in: self), let last = lastPoint else { return }
            lines.append(Line(from: last, to: point, color: penColor, width: penWidth))
            lastPoint = point
            setNeedsDisplay()
        }

        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            for line in lines {
                context.setStrokeColor(line.color.cgColor)
                context.setLineWidth(line.width)
                context.setLineCap(.round)
                context.move(to: line.from)
                context.addLine(to: line.to)
                context.strokePath()
            }
        }

        func exportDrawingImage() -> UIImage {
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
            drawHierarchy(in: bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
    }

    struct Line {
        let from: CGPoint
        let to: CGPoint
        let color: UIColor
        let width: CGFloat
    }
}
