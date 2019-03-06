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
    
    // MARK: - Reusable Properties
    let id = UUID()
    let requestDate = Date()
    let responseDate = Date()
    var request = URLRequest(url: URL(string:"https://api.3squared.com")!)
    
    var response: URLResponse {
        return HTTPURLResponse(url: request.url!,
                                       statusCode: .internalServerError,
                                       httpVersion: nil,
                                       headerFields: ["header 1" : "value 1", "header 2": "value 2"])!
    }
    
    func test_requestAndResponseMissingAllOptionalProperties_OptionalProperitesAreNotLogged() {
        let expect = expectation(description: "\(#function)")
        
        request.httpMethod = nil
        request.url = nil
        request.allHTTPHeaderFields = nil
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.request.headers, [:])
            XCTAssertNil(recording.request.body)
            XCTAssertNil(recording.response)
            XCTAssertNil(recording.host)
            XCTAssertNil(recording.path)
            XCTAssertNil(recording.query)
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_completedRecording_isLoggedWithStartAndEndTimes() {
        let expect = expectation(description: "\(#function)")
        
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertNotNil(recording.times.start)
            XCTAssertNotNil(recording.times.end)
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithHeaders_isLoggedWithHeaders() {
        let expect = expectation(description: "\(#function)")
        
        request.allHTTPHeaderFields = ["header1" : "value1", "header2" : "value 2"]
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.request.headers, ["header1" : "value1", "header2" : "value 2"])
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithMethod_isLoggedWithMethod() {
        let expect = expectation(description: "\(#function)")
        
        request.httpMethod = "POST"
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.method, "POST")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithJustHost_isLoggedWithHostAndNoPathAndQuery() {
        let expect = expectation(description: "\(#function)")
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.host, "api.3squared.com")
            XCTAssertEqual(recording.path, "")
            XCTAssertNil(recording.query)
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithPath_isLoggedWithPath() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/first/second/endpoint")!)
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.path, "/first/second/endpoint")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithQuery_isLoggedWithQuery() {
        let expect = expectation(description: "\(#function)")
        
        let request = URLRequest(url: URL(string:"https://api.3squared.com/first/second/endpoint?arg1=foo&arg2=bar")!)
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.query, "arg1=foo&arg2=bar")
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_requestWithBody_isLoggedWithBody() {
        let expect = expectation(description: "\(#function)")
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["name": "PeakNetwork", "org": "3Squared"], options: .prettyPrinted)
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            // TODO: Sort the JSON array so test passes consistently
            XCTAssertEqual(recording.request.body, "{\n  \"name\" : \"PeakNetwork\",\n  \"org\" : \"3Squared\"\n}")
            expect.fulfill()
        })
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func test_responseWithHeader_isLoggedWithHeaders() {
        let expect = expectation(description: "\(#function)")
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.response?.headers, ["header 1" : "value 1", "header 2": "value 2"])
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func test_responseWithStatusCode_isLoggedWithStatusCode() {
        let expect = expectation(description: "\(#function)")
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.response?.status, HTTPStatusCode.internalServerError.rawValue)
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: response, error: nil)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

}

struct MockFileWriter: WriteRecording {
    let callBack: (_ recording: Recording, _ filename: String) -> ()
    
    func write(_ recording: Recording, toFileNamed filename: String) {
        callBack(recording, filename)
    }
    
    
}

