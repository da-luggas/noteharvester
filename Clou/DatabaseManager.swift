//
//  DatabaseManager.swift
//  Clou
//
//  Created by Lukas Selch on 08.11.23.
//

import Foundation
import SQLite
import EPUBKit

struct Annotation: Identifiable {
    let id = UUID()
    var selectedText: String
    var note: String?
}

struct Book: Identifiable {
    let id = UUID()
    var title: String?
    var author: String?
    var annotations: [Annotation]
    var lastOpened: Int64?
    var cover: URL?
}

class DatabaseManager {
    private var annotationDB: Connection
    private var libraryDB: Connection

    init() {
        let fileManager = FileManager.default
        
        // Get the current user's home directory
        let homeDirectory = NSHomeDirectory()
        
        // Paths for the annotation and library directories
        let annotationDirectory = "\(homeDirectory)/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation"
        let libraryDirectory = "\(homeDirectory)/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary"
        
        do {
            // Find the first .sqlite file in the annotation directory
            let annotationFiles = try fileManager.contentsOfDirectory(atPath: annotationDirectory)
            let annotationDBName = annotationFiles.first { $0.hasSuffix(".sqlite") }!
            let annotationPath = "\(annotationDirectory)/\(annotationDBName)"
            
            // Find the first .sqlite file in the library directory
            let libraryFiles = try fileManager.contentsOfDirectory(atPath: libraryDirectory)
            let libraryDBName = libraryFiles.first { $0.hasSuffix(".sqlite") }!
            let libraryPath = "\(libraryDirectory)/\(libraryDBName)"
            
            // Initialize the database connections
            annotationDB = try Connection(annotationPath)
            libraryDB = try Connection(libraryPath)
        } catch {
            fatalError("Unable to open databases: \(error)")
        }
    }

    func fetchAllBooks() -> [Book] {
        do {
            let books = Table("ZBKLIBRARYASSET")
            let title = Expression<String>("ZTITLE")
            let author = Expression<String>("ZAUTHOR")
            let path = Expression<String>("ZPATH")
            let assetId = Expression<String>("ZASSETID")
            
            // Fetch all books from the library database
            return try libraryDB.prepare(books.select(title, author, path, assetId)).map { book in
                
                return Book(title: book[title], author: book[author], annotations: getAnnotations(for: book[assetId]), cover: parseCoverImageFromEPUB(at: book[path]))
            }
        } catch {
            print("Book fetch failed: \(error)")
            return []
        }
    }
    
    private func parseCoverImageFromEPUB(at filePath: String) -> URL? {
        guard let document = EPUBDocument(url: URL(fileURLWithPath: filePath)) else { return nil }

        return document.cover
    }
    
    private func getAnnotations(for assetId: String) -> [Annotation] {
        do {
            let annotations = Table("ZAEANNOTATION")
            let selectedText = Expression<String>("ZANNOTATIONSELECTEDTEXT")
            let note = Expression<String?>("ZANNOTATIONNOTE")
            let annotationAssetId = Expression<String>("ZANNOTATIONASSETID")
            
            // Fetch all annotations for a given assetId
            return try annotationDB.prepare(annotations.select(selectedText, note).where(annotationAssetId == assetId && selectedText != "")).map { annotation in
                Annotation(selectedText: annotation[selectedText], note: annotation[note])
            }
        } catch {
            print("Annotation fetch failed: \(error)")
            return []
        }
    }
}
