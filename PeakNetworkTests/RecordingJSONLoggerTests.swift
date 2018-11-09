//
//  RecordingLogger.swift
//  PeakNetwork
//
//  Created by Luke Stringer on 01/10/2018.
//  Copyright © 2018 3Squared Ltd. All rights reserved.
//

import XCTest
import PeakNetwork
@testable import PeakNetwork

class RecordingLoggerTests: XCTestCase {
    
    let requestDate = Date()
    let responseDate = Date()
    
    let request = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method")!)
    let requestWithParams = URLRequest(url: URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!)
    let jsonData = try! JSONSerialization.data(withJSONObject: ["name": "Peak", "type": "Network"], options: .prettyPrinted)
    
    func testURLWithQuery() {
        let expect = expectation(description: "\(#function)")

        let id = UUID()
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { _, filename in
            XCTAssertEqual(filename, "api.3squared.com--path-to-method-first=string-second=true-third=0.txt")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: requestWithParams)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testURLWitouthQuery() {
        let expect = expectation(description: "\(#function)")
        
        let id = UUID()
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { _, filename in
            XCTAssertEqual(filename, "api.3squared.com--path-to-method.txt")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testJSON() {
        let expect = expectation(description: "\(#function)")
        
        let id = UUID()
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
        
        logger.log(id: id, requestDate: requestDate, request: requestWithParams)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: jsonData, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testWithoutJSON() {
        let expect = expectation(description: "\(#function)")
        
        let id = UUID()
        let response = HTTPURLResponse(url: request.url!, statusCode: .ok, httpVersion: nil, headerFields: nil)
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, _ in
            // XCTAssertEqual(fileContents, "No Data. Returned with HTTP Status Code 200")
            XCTAssertEqual(fileContents, "Returned with HTTP Status Code 200")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testWithStringData() {
        let expect = expectation(description: "\(#function)")
        
        let id = UUID()
        let response = HTTPURLResponse(url: request.url!, statusCode: .ok, httpVersion: nil, headerFields: nil)
        let stringData = Data(base64Encoded: "String Response Data")
        
        let logger = RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, _ in
            XCTAssertEqual(fileContents, "String Response Data")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: stringData, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFailedHTTPCode () {
        let expect = expectation(description: "\(#function)")
    
        let id = UUID()
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
