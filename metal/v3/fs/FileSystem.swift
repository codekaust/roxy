//
//  FileSystem.swift
//  metal
//
//  Created by Ayush on 22/12/25.
//

import Foundation

class FileSystem {
    private let fileManager = FileManager.default
    
    // Get the Documents directory for the sandbox
    private var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func reset() {
        let filesToDelete = ["todo.md", "results.md", "memory.txt"]
        for file in filesToDelete {
            let url = documentsDirectory.appendingPathComponent(file)
            try? fileManager.removeItem(at: url)
        }
        print("FileSystem: Memory wiped for new run.")
    }

    func readFile(fileName: String) -> String {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            return ""
        }
    }
    
    func writeFile(fileName: String, content: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("FS Error: \(error)")
            return false
        }
    }
    
    func appendFile(fileName: String, content: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        // Check if file exists, if not create it
        if !fileManager.fileExists(atPath: fileURL.path) {
            return writeFile(fileName: fileName, content: content)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            if let data = "\n\(content)".data(using: .utf8) {
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            return true
        } catch {
            print("FS Error: \(error)")
            return false
        }
    }
}
