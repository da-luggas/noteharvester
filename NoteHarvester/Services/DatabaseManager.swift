//
//  DatabaseManager.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import Foundation
import SQLite
import EPUBKit

class DatabaseManager {
    private let APPLE_EPOCH_START: TimeInterval = 978307200 // 2001-01-01
    
    private let ANNOTATION_DB_PATH = "/users/\(NSUserName())/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/"
    private let BOOK_DB_PATH = "/users/\(NSUserName())/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/"
    
    private let SELECT_ALL_ANNOTATIONS_QUERY = """
    SELECT 
      ZANNOTATIONASSETID as assetId,
      ZANNOTATIONSELECTEDTEXT as quote,
      ZANNOTATIONNOTE as comment,
      ZFUTUREPROOFING5 as chapter,
      ZANNOTATIONSTYLE as colorCode,
      ZANNOTATIONMODIFICATIONDATE as modifiedAt,
      ZANNOTATIONCREATIONDATE as createdAt
    FROM ZAEANNOTATION
    WHERE ZANNOTATIONDELETED = 0 
      AND ZANNOTATIONSELECTEDTEXT IS NOT NULL 
      AND ZANNOTATIONSELECTEDTEXT <> ''
    ORDER BY ZANNOTATIONASSETID, ZPLLOCATIONRANGESTART;
    """
    
    private let SELECT_ALL_BOOKS_QUERY = """
    SELECT ZASSETID as id, ZTITLE as title, ZAUTHOR as author, ZPATH as path FROM ZBKLIBRARYASSET;
    """
    
    func getBooks() throws -> [Book] {
        let booksFiles = try FileManager.default.contentsOfDirectory(atPath: BOOK_DB_PATH).filter { $0.hasSuffix(".sqlite") }
        var books: [Book] = []
        
        for file in booksFiles {
            let db = try Connection("\(BOOK_DB_PATH)/\(file)")
            let stmt = try db.prepare(SELECT_ALL_BOOKS_QUERY)
            for row in stmt {
                let id = row[0] as! String
                let title = row[1] as! String
                let author = row[2] as! String
                guard let coverPathString = row[3] as? String else {
                    continue
                }
                let cover = parseCoverImage(bookPathString: coverPathString)
                
                let annotations = try getAnnotations(forBookId: id)
                books.append(Book(id: id, title: title, author: author, cover: cover, annotations: annotations))
            }
        }
        
        return books
    }
    
    private func getAnnotations(forBookId bookId: String) throws -> [Annotation] {
        let annotationsFiles = try FileManager.default.contentsOfDirectory(atPath: ANNOTATION_DB_PATH).filter { $0.hasSuffix(".sqlite") }
        var annotations: [Annotation] = []
        
        for file in annotationsFiles {
            let db = try Connection("\(ANNOTATION_DB_PATH)/\(file)")
            let stmt = try db.prepare(SELECT_ALL_ANNOTATIONS_QUERY)
            for row in stmt {
                if row[0] as! String == bookId {
                    if let assetId = row[0] as? String {
                        annotations.append(Annotation(
                            assetId: assetId,
                            quote: row[1] as? String,
                            comment: row[2] as? String,
                            chapter: row[3] as? String,
                            colorCode: row[4] as? Int64,
                            modifiedAt: (row[5] as? Int).flatMap { convertAppleTime($0) },
                            createdAt: (row[6] as? Int).flatMap { convertAppleTime($0) }
                        ))
                    }
                }
            }
        }
        
        return annotations
    }
    
    private func convertAppleTime(_ appleTime: Int) -> TimeInterval {
        return APPLE_EPOCH_START + TimeInterval(appleTime)
    }
    
    private func parseCoverImage(bookPathString: String) -> URL? {
        guard let document = EPUBDocument(url: URL(fileURLWithPath: bookPathString)) else { return nil }
        return document.cover
    }
    
    func exportAnnotationsToCSV(annotations: [Annotation], fileName: String) throws {
        let csvString = annotations.map { annotation in
            return "\(annotation.assetId),\(annotation.quote ?? ""),\(annotation.comment ?? ""),\(annotation.chapter ?? ""),\(annotation.modifiedAt ?? 0),\(annotation.createdAt ?? 0)"
        }.joined(separator: "\n")
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Annotations exported to: \(fileURL.path)")
    }
}

struct Book: Hashable {
    let id: String
    let title: String
    let author: String
    let cover: URL?
    let annotations: [Annotation]
    
    var latestAnnotationDate: TimeInterval {
        annotations.map { $0.modifiedAt ?? $0.createdAt ?? 0 }.max() ?? 0
    }
}

struct Annotation: Hashable {
    let id: UUID = UUID()
    let assetId: String
    let quote: String?
    let comment: String?
    let chapter: String?
    let colorCode: Int64?
    let modifiedAt: TimeInterval?
    let createdAt: TimeInterval?
}
