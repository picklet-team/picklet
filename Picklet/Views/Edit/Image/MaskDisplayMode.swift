//
//  MaskDisplayMode.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI

struct MaskEditorView: View {
    @Binding var imageSet: EditableImageSet
    @Environment(\.dismiss) var dismiss

    // MARK: - Simplified State
    
    @State private var zoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Display only the original image for simplicity
                Image(uiImage: imageSet.original)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .offset(offset)
            }
//            .gesture(zoomPanGesture()) // Retain zoom and pan gestures
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("完了") { dismiss() } // Simplified toolbar with only a dismiss button
            }
        }
    }

//    /// Simplified zoom and pan gesture
//    private func zoomPanGesture() -> some Gesture {
//        SimultaneousGesture(
//            MagnificationGesture().onChanged { zoomScale = $0 },
//            DragGesture().onChanged { offset = $0.translation }
//        )
//    }
}
