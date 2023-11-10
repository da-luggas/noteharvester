//
//  ContentView.swift
//  Clou
//
//  Created by Lukas Selch on 08.11.23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BooksViewModel()

    var body: some View {
        NavigationSplitView {
            List(viewModel.books, id: \.id, selection: $viewModel.selectedBooks) { book in
                BookEntry(title: book.title, author: book.author, annotations: book.annotations, cover: book.cover)
            }
        } detail: {
            if viewModel.selectedBooks.isEmpty {
                Text("Select one or more books to view the highlighted text")
            } else {
                AnnotationsView(books: viewModel.books.filter { viewModel.selectedBooks.contains($0.id) })
                    .environmentObject(viewModel)
            }
        }
        .navigationTitle("Clou")
        
    }
}

struct AnnotationsView: View {
    @EnvironmentObject var viewModel: BooksViewModel
    let books: [Book]
    
    var body: some View {
        List(selection: $viewModel.selectedAnnotations) {
            ForEach(books, id: \.id) { book in
                Section(header: Text(book.title ?? "Unknown Title")) {
                    ForEach(book.annotations) { annotation in
                        VStack(alignment: .leading) {
                            Text(annotation.selectedText)
                                .padding([.bottom, .top])
                            if let note = annotation.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .italic()
                                    .padding([.bottom])
                            }
                        }
                    }
                }
            }
        }
        .contextMenu {
            if !viewModel.selectedAnnotations.isEmpty {
                Button("Copy Raw Text") {
                    viewModel.copyToClipboard()
                }
            }
        }
        .toolbar {
            ToolbarItem {
                if !viewModel.selectedAnnotations.isEmpty {
                    Button(action: {
                        viewModel.saveCSV()
                    }) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }
}

struct BookEntry: View {
    let title: String?
    let author: String?
    let annotations: [Annotation]
    let cover: URL?

    var body: some View {
        HStack {
            if let coverURL = cover {
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
                Text(author ?? "Unknown Author")
                    .font(.caption)
                Text(title ?? "Unknown Title")
                    .font(.headline)
                Text("\(annotations.count) Highlights")
            }
        }
    }
}

#Preview {
    ContentView()
}
