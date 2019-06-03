//
//  ErrorInterceptorSessionTests.swift
//  PeakNetworkTests
//
//  Created by Sam Oakley on 22/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

import XCTest
#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class ErrorInterceptorSessionTests: XCTestCase {
    
    func testInterceptorIsCalledForError()  {
        let expect = expectation(description: "")

        let baseSession = MockSession { session in
            session.queue(response: MockResponse(statusCode: .internalServerError, error: TestError.justATest))
        }
        
        let session = ErrorInterceptorSession(with: baseSession) { _, _, error in
            switch (error) {
            case TestError.justATest:
                expect.fulfill()
            default:
                XCTFail()
            }
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        session.dataTask(with: request) { _, _, _ in }.resume()
        
        waitForExpectations(timeout: 1)
    }
    
    func testInterceptorIsNotCalledForSuccessfulResponse()  {
        let expect = expectation(description: "")
        
        let baseSession = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
        }
        
        let session = ErrorInterceptorSession(with: baseSession) { _, _, error in
            XCTFail()
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        session.dataTask(with: request) { _, _, _ in
            expect.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 1)
    }

    
    public enum TestError: Error {
        case justATest
    }
}
