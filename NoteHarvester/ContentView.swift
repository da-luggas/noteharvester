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
    @State var selectedAnnotations: Set<Annotation> = Set<Annotation>()
    
    private let databaseManager = DatabaseManager()

    var body: some View {
        NavigationSplitView {
            List(books, id: \.self, selection: $selectedBooks) { book in
                HStack {
                    if let coverURL = book.cover {
                        AsyncImage(url: coverURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 60)
                        } placeholder: {
                            Image(systemName: "book.closed")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 60)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(systemName: "book.closed")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 60)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(book.author)
                            .font(.caption)
                        Text(book.title)
                            .font(.headline)
                        Text(book.annotations.count == 1 ? "1 Highlight" : "\(book.annotations.count) Highlights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } detail: {
            if selectedBooks.isEmpty {
                Text("Select one or more books to view annotations.")
            } else {
                let selectedAnnotations = selectedBooks.flatMap { $0.annotations }
                if selectedAnnotations.isEmpty {
                    Text("There are no annotations in the selected books.")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    List(selectedAnnotations, id: \.self, selection: $selectedAnnotations) { annotation in
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
        }
        .onAppear() {
            loadBooks()
        }
        .frame(minWidth: 600, minHeight: 400)
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
