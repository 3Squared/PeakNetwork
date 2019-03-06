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
    
    func test_requestWithHeaders_isLoggedWithHeaders() {
        let expect = expectation(description: "\(#function)")
        
        var request = URLRequest(url: URL(string:"https://api.3squared.com")!)
        request.allHTTPHeaderFields = ["header1" : "value1", "header2" : "value 2"]
        let id = UUID()
        let requestDate = Date()
        let responseDate = Date()
        
        
        let logger = RecordingLogger(writer: MockFileWriter() { recording, _ in
            XCTAssertEqual(recording.request.headers, ["header1" : "value1", "header2" : "value 2"])
            
            expect.fulfill()
        })
        
        logger.log(id: id, requestDate: requestDate, request: request)
        logger.log(id: id, requestDate: requestDate, responseDate: responseDate, data: nil, response: nil, error: nil)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

}

struct MockFileWriter: WriteRecording {
    let callBack: (_ recording: Recording, _ filename: String) -> ()
    
    func write(_ recording: Recording, toFileNamed filename: String) {
        callBack(recording, filename)
    }
    
    
}

