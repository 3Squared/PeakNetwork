//
//  JSONRecordingLogger.swift
//  PeakNetwork
//
//  Created by Luke Stringer on 01/10/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

public class RecordingLogger: Logger {
    
    fileprivate var idToURLRequestMap = [UUID: URLRequest]()
    
    let writer: WriteRecording
    
    public init(writer: WriteRecording = FileWriter()) {
        self.writer = writer
    }
    
    public func log(id: UUID, requestDate: Date, request: URLRequest) {
        idToURLRequestMap[id] = request
    }
    
    public func log(id: UUID, requestDate: Date, responseDate: Date, data: Data?, response urlResponse: URLResponse?, error: Error?) {
        guard
            let urlRequest = idToURLRequestMap[id],
            let method = urlRequest.httpMethod,
            let url = urlRequest.url
            else { return }
        
        let request = Recording.Request(urlRequest: urlRequest)
        let response = Recording.Response(urlResponse: urlResponse, data: data)
        let times = Recording.Times(start: requestDate, end: responseDate)
        let recording = Recording(method: method, host: url.host, path: url.path, query: url.query, times: times, request: request, response: response)
        
        writer.write(recording, toFileNamed: "\(Int(requestDate.timeIntervalSince1970)).json" )
        
    }
}

public protocol WriteRecording {
    func write(_ recording: Recording, toFileNamed filename: String)
}

public struct FileWriter: WriteRecording {
    public init() {}
    
    public func write(_ recording: Recording, toFileNamed filename: String) {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get Documents Directory URL")
            return
        }
        
        let fileURL = documents.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(recording)
            guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                print("Failed to convert data to String")
                return
            }
            print(string)
            try string.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
            print("Failed to write JSON with error: \n \(error)")
        }
        
    }
}

