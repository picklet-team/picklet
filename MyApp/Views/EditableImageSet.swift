//
//  EditableImageSet.swift
//  MyApp
//
//  Created by al dente on 2025/04/29.
//


import SwiftUI

struct EditableImageSet: Identifiable {
    let id: UUID
    var original: UIImage?
    var originalUrl: String?
    var mask: UIImage?
    var maskUrl: String?
    var result: UIImage?
    var resultUrl: String?
    var isNew: Bool
}

extension EditableImageSet {
    init(original: UIImage) {
        self.id = UUID()
        self.original = original
        self.originalUrl = nil
        self.mask = nil
        self.maskUrl = nil
        self.result = nil
        self.resultUrl = nil
        self.isNew = true
    }
}
