//
//  ContentView.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import SwiftUI

struct ContentView: View {
    @State var books: [Book] = []
    @State var selectedBooks: Set<Book> = []
    @State var annotations: [Annotation] = []
    @State var selectedAnnotations: Set<Annotation> = Set<Annotation>()
    
    private let databaseManager = DatabaseManager()

    var body: some View {
        NavigationSplitView {
            List(books, id: \.self, selection: $selectedBooks) { book in
                VStack(alignment: .leading) {
                    Text(book.title)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        } detail: {
            if annotations.isEmpty {
                Text("Select one or more books to view annotations.")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                List(annotations, id: \.self, selection: $selectedAnnotations) { annotation in
                    VStack(alignment: .leading) {
                        Text(annotation.quote)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let comment = annotation.comment {
                            Text(comment)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .onAppear() {
            loadBooks()
        }
        .onChange(of: selectedBooks) {
            loadAnnotations()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
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
    
    private func loadBooks() {
        do {
            self.books = try databaseManager.getBooks()
        } catch {
            print("Failed to load books: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
