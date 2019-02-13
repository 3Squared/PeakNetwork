//
//  RecordingLoggerTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Luke Stringer on 13/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

import XCTest

#if os(iOS)

@testable import PeakNetwork_iOS

#else

@testable import PeakNetwork_macOS

#endif

class RecordingLoggerTests: XCTestCase {
    
    func testIntegrationWithOperations() {
        
        let expect = expectation(description: "\(#function)")
        
        let request1 = Request (
            URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!
        )
        
        let request2 = Request (
            URL(string:"https://api.3squared.com/path/to/another?first=1")!
        )
        
        let mockSession = MockSession { session in
            session.queue(response: MockResponse(json: ["name": "Peak", "type": "Network"], statusCode: .ok))
            session.queue(response: MockResponse(json: ["name": "Apple"], statusCode: .ok))
        }
        
        var writeCount = 0
        
        let loggingSession = LoggingSession(with: mockSession, logger: RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, filename in
            
            switch writeCount {
            case 0:
                XCTAssertEqual(filename, "api.3squared.com--path-to-method-first=string-second=true-third=0")
                XCTAssertEqual(fileContents,
                               """
                {
                  "name" : "Peak",
                  "type" : "Network"
                }
                """
                )
            case 1:
                XCTAssertEqual(filename, "api.3squared.com--path-to-another-first=1")
                XCTAssertEqual(fileContents,
                               """
                {
                  "name" : "Apple"
                }
                """)
                expect.fulfill()
            default: XCTFail()
            }
            
            writeCount += 1
            
        }))
        
        let operation1 = URLResponseOperation(request1, session: loggingSession)
        let operation2 = URLResponseOperation(request2, session: loggingSession)
        
        operation1.then(do: operation2).enqueue()
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testURLWithQuery() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!)
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        let jsonData = try! JSONSerialization.data(withJSONObject: ["name": "Peak", "type": "Network"], options: .prettyPrinted)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { _, filename in
            XCTAssertEqual(filename, "api.3squared.com--path-to-method-first=string-second=true-third=0")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testURLWitouthQuery() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method")!)
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        let jsonData = try! JSONSerialization.data(withJSONObject: ["name": "Peak", "type": "Network"], options: .prettyPrinted)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { _, filename in
            XCTAssertEqual(filename, "api.3squared.com--path-to-method")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testJSON() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!)
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        let jsonData = try! JSONSerialization.data(withJSONObject: ["name": "Peak", "type": "Network"], options: .prettyPrinted)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, _ in
            XCTAssertEqual(fileContents,
                           """
            {
              "name" : "Peak",
              "type" : "Network"
            }
            """
            )
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testWithoutJSON() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method")!)
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        let response = HTTPURLResponse(url: request.url!, statusCode: .ok, httpVersion: nil, headerFields: nil)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, _ in
            XCTAssertEqual(fileContents, "Returned with HTTP Status Code 200")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFailedHTTPCode () {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method")!)
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        let response = HTTPURLResponse(url: request.url!, statusCode: .internalServerError, httpVersion: nil, headerFields: nil)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, _ in
            XCTAssertEqual(fileContents, "Returned with HTTP Status Code 500")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}


struct MockFileWriter: WriteFile {
    let callBack: (_ string: String, _ fileName: String) -> ()
    
    func write(_ string: String, toFileNamed filename: String) {
        callBack(string, filename)
    }
}
