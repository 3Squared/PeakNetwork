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

	func testLogger() {
		
		let expect = expectation(description: "testLogger")
		
        let request = URLRequestable(
            URL(string:"https://api.3squared.com/path/to/method?first=string&second=true&third=0")!
        )
        
		let mockSession = MockSession { session in
            session.queue(response: MockResponse(json: ["name": "Peak", "type": "Network"], statusCode: .ok))
		}
		
		let loggingSession = LoggingSession(with: mockSession, logger: RecordingJSONLogger(fileWriter: MockFileWriter { fileContents, filename in
            
            XCTAssertEqual(filename, "api.3squared.com--path-to-method-first=string-second=true-third=0")
            XCTAssertEqual(fileContents,
            """
            {
              "name" : "Peak",
              "type" : "Network"
            }
            """
            )
            
            expect.fulfill()
		}))
		
		let operation = URLResponseOperation(request, session: loggingSession)
		operation.enqueue()
		
		waitForExpectations(timeout: 1.0, handler: nil)
	}
}


struct MockFileWriter: WriteFile {
    let callBack: (_ string: String, _ fileName: String) -> ()
    
    func write(_ string: String, toFileNamed filename: String) {
        callBack(string, filename)
    }
}
