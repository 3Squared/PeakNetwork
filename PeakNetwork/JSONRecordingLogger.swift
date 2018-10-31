//
//  JSONRecordingLogger.swift
//  PeakNetwork
//
//  Created by Luke Stringer on 01/10/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

public class RecordingJSONLogger: Logger {
    fileprivate var idToRequestURL = [UUID: URL]()
    
    let fileWriter: WriteFile
    
    init(fileWriter: WriteFile = FileWriter()) {
        self.fileWriter = fileWriter
    }
    
    public func log(id: UUID, requestDate: Date, request: URLRequest) {
        guard let url = request.url else { return }
        idToRequestURL[id] = url
    }
    
    public func log(id: UUID, requestDate: Date, responseDate: Date, data: Data?, response: URLResponse?, error: Error?) {
        // TODO: Error handling
        guard
            let requestURL = idToRequestURL[id],
            let host = requestURL.host,
            let jsonData = data,
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments),
            let prettyJSONData = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted]),
            let jsonString = String(data: prettyJSONData, encoding: String.Encoding.utf8)
            else { return }
        
        let queryAppend = requestURL.query.flatMap { "-" + $0 } ?? ""
        
        let filename = (host + "-" + requestURL.path + queryAppend)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "&", with: "-")
        fileWriter.write(jsonString, toFileNamed: filename)
    }
}

protocol WriteFile {
    func write(_ string: String, toFileNamed filename: String)
}

struct FileWriter: WriteFile {
    func write(_ string: String, toFileNamed filename: String) {
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = documents.appendingPathComponent(filename)
            
            do {
                try string.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print("Failed to write JSON with error: \n \(error)")
            }
        }
        else {
            print("Failed to get Documents Directory URL")
        }
    }
}

