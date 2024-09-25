//
//  ContentView.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import SwiftUI

struct ContentView: View {
    @State private var books: [Book] = []
    @State private var selectedBook: Book?
    @State private var annotations: [Annotation] = []
    private let databaseManager = DatabaseManager()

    var body: some View {
        NavigationSplitView {
            List(books, id: \.id, selection: $selectedBook) { book in
                Text(book.title)
            }
            .onAppear {
                do {
                    books = try databaseManager.getBooks()
                } catch {
                    print("Failed to load books: \(error)")
                }
            }
        } detail: {
            if let selectedBook = selectedBook {
                List(annotations, id: \.assetId) { annotation in
                    VStack(alignment: .leading) {
                        Text(annotation.quote)
                            .font(.headline)
                        Text(annotation.comment)
                            .font(.subheadline)
                    }
                }
                .onAppear {
                    do {
                        annotations = try databaseManager.getAnnotations(forBookId: selectedBook.id)
                    } catch {
                        print("Failed to load annotations: \(error)")
                    }
                }
            } else {
                Text("Select a book to view annotations")
            }
        }
    }
}

#Preview {
    ContentView()
}
