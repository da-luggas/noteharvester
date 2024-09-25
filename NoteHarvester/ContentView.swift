//
//  ContentView.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationSplitView {
            // Left side: List of books with multi-selection enabled
            List(viewModel.books, id: \.self, selection: $viewModel.selectedBooks) { book in
                VStack(alignment: .leading) {
                    Text(book.title)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .onChange(of: viewModel.selectedBooks) { _ in
                DispatchQueue.main.async {
                    viewModel.loadAnnotations() // Load annotations when selected books change
                }
            }
            .navigationTitle("Books")
        } detail: {
            if viewModel.annotations.isEmpty {
                Text("Select one or more books to view annotations.")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                // Right side: List of annotations, selectable
                List(viewModel.annotations, id: \.self, selection: $viewModel.selectedAnnotation) { annotation in
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
                .navigationTitle("Annotations")
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
