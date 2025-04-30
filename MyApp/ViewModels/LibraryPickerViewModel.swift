//
//  LibraryPickerViewModel.swift
//  MyApp
//
//  Created by al dente on 2025/04/30.
//


// ViewModels/LibraryPickerViewModel.swift
import SwiftUI
import Combine

@MainActor
final class LibraryPickerViewModel: ObservableObject {
    @Published var urls: [URL] = []
    
    private var cancellables = Set<AnyCancellable>()
    
  func fetch() {
      Task {
          do {
              self.urls = try await SupabaseService.shared.listClothingImageURLs()
          } catch {
              print("❌ image fetch error:", error)
          }
      }
    }
}
