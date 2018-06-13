//
//  WebService.swift
//  NetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import THRNetwork
import THRResult

class WebService {
    
    static let shared = WebService()
    
    struct Constants {
        static let baseURL = "https://example.com/"
    }
    
    var session: Session
    let queue: OperationQueue

    lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var requestCount = 0
    
    init(session: Session = URLSession.shared, queue: OperationQueue = OperationQueue()) {
        self.queue = queue
        self.session = LoggingSession(with: MockSession(fallbackToSession: session, configure: { session in
            session.queue(response: MockResponse(fileName: "Example1", responseHeaders: ["X-CustomHeader" : "This is a header"]))
            session.queue(response: MockResponse(statusCode: nil, error: RuntimeError("All these responses are mocked. This error was queued in \(#file) on line \(#line).")))
            session.queue(response: MockResponse(fileName: "Example2"))
            session.queue(response: MockResponse(json: ["errorMessage": "Hello World!"], statusCode: .internalServerError))
            session.queue(response: MockResponse(fileName: "Example1", sticky: true))
        }), logger: JSONLogger() { url in
            return url?.absoluteString.contains("example.com") ?? true
        })
    }
}

struct RuntimeError: LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var errorDescription: String? {
        return message
    }
}
