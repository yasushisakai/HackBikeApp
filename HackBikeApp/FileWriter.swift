//
//  FileWriter.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/23/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import Foundation

enum FileError: Error {
    case notFound
    case invalidContents
    case couldNotCreateFile
    case unknown
}

enum Directories: String {
    case Documents
    case Temp = "tmp"
}

class FileWriter {
    
    let fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    static func write(to fileName: String, contents: [String]) throws {
        let file = FileWriter(fileName: fileName)
        try file.writeLines(contents: contents, to: .Documents)
    }
    
    static func getUrl(for directory: Directories) throws -> URL {
        switch directory{
        case .Documents:
            guard let result = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw FileError.notFound
            }
            return result
        case .Temp:
            return FileManager.default.temporaryDirectory
        }
    }
    
    static func createFullPath(for filename: String, in directory: Directories) throws -> URL {
        return try FileWriter.getUrl(for: directory).appendingPathComponent(filename)
    }
    
    func write(contents: String, to path: Directories) throws {
        let fullPath = try FileWriter.createFullPath(for: fileName, in: path)
        
        guard let data = contents.data(using: .utf8, allowLossyConversion: true) else {
            throw FileError.invalidContents
        }
        
        if !FileManager.default.createFile(atPath: fullPath.path, contents: data, attributes: nil) {
            throw FileError.couldNotCreateFile
        }
    }
    
    func writeLines(contents: [String], to path: Directories) throws {
        let concatLines = contents.reduce("") { $0 + $1 + "\n" }
        return try write(contents: concatLines, to: path)
    }

}
