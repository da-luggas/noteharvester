//
//  BooksViewModel.swift
//  Clou
//
//  Created by Lukas Selch on 09.11.23.
//

import Foundation
import AppKit
import Combine

class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var selectedBooks: Set<UUID> = []
    @Published var selectedAnnotations: Set<UUID> = []
    
    private let dbManager = DatabaseManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.books = dbManager.fetchAllBooks().filter { $0.annotations.count > 0}
        setupObservers()
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let selectedAnnotationsTexts = books
            .flatMap { $0.annotations }
            .filter { selectedAnnotations.contains($0.id) }
            .map { $0.selectedText }
            .joined(separator: "\n\n")
        pasteboard.setString(selectedAnnotationsTexts, forType: .string)
    }
    
    func saveCSV() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "annotations.csv"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let csvData = self.fetchSelectedCSV()
                do {
                    try csvData.write(to: url, atomically: true, encoding: .utf8)
                    print("Successfully saved CSV at \(url.path)")
                } catch {
                    print("Failed to save CSV: \(error)")
                }
            }
        }
    }
    
    private func setupObservers() {
        // Observe changes to `selectedBooks`
        $selectedBooks
            .sink { [weak self] _ in
                self?.selectedAnnotations.removeAll()
            }
            .store(in: &cancellables)
    }
    
    private func fetchSelectedCSV() -> String {
        var csvText = "Author;Title;Highlight;Note\n"
        
        // Assuming books are already loaded and annotations are linked to the correct books
        for book in books where selectedAnnotations.contains(where: { annotationId in
            book.annotations.contains { $0.id == annotationId }
        }) {
            for annotation in book.annotations where selectedAnnotations.contains(annotation.id) {
                let authorString = "\"\(book.author?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown Author")\""
                let titleString = "\"\(book.title?.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown Title")\""
                let highlightString = "\"\(annotation.selectedText.replacingOccurrences(of: "\"", with: "\"\""))\""
                let noteString = "\"\(annotation.note?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
                
                let newLine = "\(authorString);\(titleString);\(highlightString);\(noteString)\n"
                csvText.append(contentsOf: newLine)
            }
        }
        
        return csvText
    }
}
