//
//  ContentViewModel.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import Foundation

class ContentViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var selectedBooks: Set<Book> = [] // Multi-selection of books
    @Published var annotations: [Annotation] = []
    @Published var selectedAnnotation: Annotation? // To allow selection of annotations
    
    private let databaseManager = DatabaseManager()
    
    init() {
        loadBooks()
    }
    
    // Load books from the database
    private func loadBooks() {
        do {
            self.books = try databaseManager.getBooks()
        } catch {
            print("Failed to load books: \(error)")
        }
    }
    
    // Load annotations for the selected books
    func loadAnnotations() {
        annotations.removeAll() // Clear previous annotations
        
        for book in selectedBooks {
            do {
                let bookAnnotations = try databaseManager.getAnnotations(forBookId: book.id)
                annotations.append(contentsOf: bookAnnotations)
            } catch {
                print("Failed to load annotations for book \(book.id): \(error)")
            }
        }
        
        annotations.sort { $0.createdAt ?? 0 < $1.createdAt ?? 0 } // Sort annotations by creation date
    }
}
