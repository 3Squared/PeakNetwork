//
//  URLSession+Mock.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 05/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation
import PeakNetwork

extension URLSession {
    
    static let mock: Session = LoggingSession(with: MockSession(configure: { session in
        session.queue(response: MockResponse(fileName: "Example1", responseHeaders: ["X-CustomHeader" : "This is a header"]))
        session.queue(response: MockResponse(statusCode: nil, error: RuntimeError("All these responses are mocked. This error was queued in \(#file) on line \(#line).")))
        session.queue(response: MockResponse(fileName: "Example2"))
        session.queue(response: MockResponse(json: ["errorMessage": "Hello World!"], statusCode: .internalServerError))
        session.queue(response: MockResponse(fileName: "Example1", sticky: true))
    }), logger: JSONLogger() { url in
        return url?.absoluteString.contains("example.com") ?? true
    })
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

