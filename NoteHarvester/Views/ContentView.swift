//
//  ContentView.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State var books: [Book] = []
    @State var selectedBooks: Set<Book> = []
    @State var selectedAnnotations: Set<Annotation> = Set<Annotation>()
    @State private var isExportMenuPresented = false
    @State private var bookSearchText = ""
    @State private var annotationSearchText = ""
    
    private let databaseManager = DatabaseManager()
    @State private var keyboardMonitor: Any?
    
    var filteredBooks: [Book] {
        if bookSearchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.lowercased().contains(bookSearchText.lowercased()) ||
                book.author.lowercased().contains(bookSearchText.lowercased())
            }
        }
    }

    var filteredAnnotations: [Annotation] {
        let selectedAnnotations = selectedBooks.flatMap { $0.annotations }
        if annotationSearchText.isEmpty {
            return selectedAnnotations
        } else {
            return selectedAnnotations.filter { annotation in
                annotation.quote?.lowercased().contains(annotationSearchText.lowercased()) ?? false ||
                annotation.comment?.lowercased().contains(annotationSearchText.lowercased()) ?? false
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(filteredBooks, id: \.self, selection: $selectedBooks) { book in
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
            .searchable(text: $bookSearchText, placement: .sidebar, prompt: "Search books")
            .onChange(of: bookSearchText) { _ in
                selectedAnnotations.removeAll()
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
                    List(filteredAnnotations, id: \.self, selection: $selectedAnnotations) { annotation in
                        VStack(alignment: .leading) {
                            if let quote = annotation.quote {
                                if colorForCode(annotation.colorCode) == .clear {
                                    Text(quote)
                                        .font(.body)
                                        .underline(color: .red)
                                        .padding(.horizontal, 3)
                                } else {
                                    Text(quote)
                                        .font(.body)
                                        .background(
                                            colorForCode(annotation.colorCode)
                                                .opacity(0.3)
                                                .cornerRadius(3)
                                                .padding(.horizontal, -3)
                                        )
                                        .padding(.horizontal, 3)
                                }
                            }
                            if let comment = annotation.comment {
                                Text("- \(comment)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .searchable(text: $annotationSearchText, placement: .toolbar, prompt: "Search annotations")
                    .contextMenu {
                        Button(action: {
                            copySelectedAnnotations()
                        }) {
                            Text("Copy Selection")
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    isExportMenuPresented = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedAnnotations.isEmpty)
                .popover(isPresented: $isExportMenuPresented, arrowEdge: .bottom) {
                    VStack {
                        Button(action: {
                            exportAsCSV()
                            isExportMenuPresented = false
                        }) {
                            Label("Export as CSV", systemImage: "doc.plaintext")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadBooks()
            setupKeyboardShortcut()
        }
        .onDisappear {
            removeKeyboardShortcut()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func loadBooks() {
        do {
            var books = try databaseManager.getBooks()
            books.sort { $0.latestAnnotationDate <= $1.latestAnnotationDate }
            self.books = books
        } catch {
            print("Failed to load books: \(error)")
        }
    }
    
    private func colorForCode(_ code: Int64?) -> Color {
        switch code {
        case 0:
            return .clear
        case 1:
            return .green
        case 2:
            return .blue
        case 3:
            return .yellow
        case 4:
            return .pink
        case 5:
            return .purple
        default:
            return .primary
        }
    }
    
    private func copySelectedAnnotations() {
        let copiedText = selectedAnnotations.map { annotation in
            var text = ""
            if let quote = annotation.quote {
                text += "\"\(quote)\"\n"
            }
            if let comment = annotation.comment {
                text += "Note: \(comment)\n"
            }
            return text
        }.joined(separator: "\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copiedText, forType: .string)
    }
    
    private func setupKeyboardShortcut() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.keyCode == 8 { // 'C' key
                copySelectedAnnotations()
                return nil // Consumed the event
            }
            return event
        }
    }
    
    private func removeKeyboardShortcut() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func exportAsCSV() {
        let csvString = "Author,Book Title,Quote,Comment\n" +
        selectedAnnotations.map { annotation in
            let book = books.first { $0.annotations.contains(annotation) }!
            return "\"\(book.author)\",\"\(book.title)\",\"\(annotation.quote ?? "")\",\"\(annotation.comment ?? "")\""
        }.joined(separator: "\n")
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "exported_annotations.csv"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save CSV: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
