//
//  RecordingJSONLoggerIntegrationTests.swift
//  PeakNetworkTests
//
//  Created by Luke Stringer on 09/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import XCTest
import PeakNetwork
@testable import PeakNetwork

class RecordingJSONLoggerIntegrationTests: XCTestCase {

    func testIntegrationWithOperations() {
        
        let expect = expectation(description: "\(#function)")
        
        let request1 = URLRequestable(
            URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!
        )
        
        let request2 = URLRequestable(
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
                XCTAssertEqual(filename, "api.3squared.com--path-to-method-first=string-second=true-third=0.txt")
                XCTAssertEqual(fileContents,
                               """
                {
                  "name" : "Peak",
                  "type" : "Network"
                }
                """
                )
            case 1:
                XCTAssertEqual(filename, "api.3squared.com--path-to-another-first=1.txt")
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

}
