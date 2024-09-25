//
//  DatabaseManager.swift
//  NoteHarvester
//
//  Created by Lukas Selch on 25.09.24.
//

import Foundation
import SQLite

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
    SELECT ZASSETID as id, ZTITLE as title, ZAUTHOR as author FROM ZBKLIBRARYASSET;
    """
    
    func getBooks() throws -> [Book] {
        let booksFiles = try FileManager.default.contentsOfDirectory(atPath: BOOK_DB_PATH).filter { $0.hasSuffix(".sqlite") }
        var books: [Book] = []
        
        for file in booksFiles {
            let db = try Connection("\(BOOK_DB_PATH)/\(file)")
            let stmt = try db.prepare(SELECT_ALL_BOOKS_QUERY)
            for row in stmt {
                books.append(Book(id: row[0] as! String, title: row[1] as! String, author: row[2] as! String))
            }
        }
        
        return books
    }
    
    func getAnnotations() throws -> [Annotation] {
        let annotationsFiles = try FileManager.default.contentsOfDirectory(atPath: ANNOTATION_DB_PATH).filter { $0.hasSuffix(".sqlite") }
        var annotations: [Annotation] = []
        
        for file in annotationsFiles {
            let db = try Connection("\(ANNOTATION_DB_PATH)/\(file)")
            let stmt = try db.prepare(SELECT_ALL_ANNOTATIONS_QUERY)
            for row in stmt {
                annotations.append(Annotation(
                    assetId: row[0] as! String,
                    quote: row[1] as! String,
                    comment: row[2] as! String,
                    chapter: row[3] as! String,
                    colorCode: row[4] as! String,
                    modifiedAt: convertAppleTime(row[5] as! Int),
                    createdAt: convertAppleTime(row[6] as! Int)
                ))
            }
        }
        
        return annotations
    }
    
    private func convertAppleTime(_ appleTime: Int) -> TimeInterval {
        return APPLE_EPOCH_START + TimeInterval(appleTime)
    }
}

struct Book {
    let id: String
    let title: String
    let author: String
}

struct Annotation {
    let assetId: String
    let quote: String
    let comment: String
    let chapter: String
    let colorCode: String
    let modifiedAt: TimeInterval
    let createdAt: TimeInterval
}
