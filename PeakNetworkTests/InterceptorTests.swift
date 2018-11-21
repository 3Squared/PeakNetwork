//
//  InterceptorTests.swift
//  PeakNetworkTests
//
//  Created by Sam Oakley on 21/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

import XCTest
@testable import PeakNetwork

class InterceptorTests: XCTestCase {
    
    func testSingleInterceptor()  {
        let baseSession = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
        }
        
        let session = InterceptorSession(with: baseSession) { request in
            request.setValue("intercepted", forHTTPHeaderField: "request")
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        let task = session.dataTask(with: request) { _, _, _ in }
    
        XCTAssertEqual(task.originalRequest!.value(forHTTPHeaderField: "request"), "intercepted")
    }
    
    func testMultipleInterceptors()  {
        let baseSession = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
        }
        
        let session = InterceptorSession(with: baseSession, interceptors: [
            { request in
                request.setValue("1", forHTTPHeaderField: "a")
            },
            { request in
                request.setValue("2", forHTTPHeaderField: "b")
            }
        ])
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        let task = session.dataTask(with: request) { _, _, _ in }
        
        XCTAssertEqual(task.originalRequest!.value(forHTTPHeaderField: "a"), "1")
        XCTAssertEqual(task.originalRequest!.value(forHTTPHeaderField: "b"), "2")
    }

    func testAddInterceptor()  {
        let baseSession = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
        }
        
        let session = InterceptorSession(with: baseSession) { request in
            request.setValue("1", forHTTPHeaderField: "a")
        }
        
        session.add { request in
            request.setValue("2", forHTTPHeaderField: "b")
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        let task = session.dataTask(with: request) { _, _, _ in }
        
        XCTAssertEqual(task.originalRequest!.value(forHTTPHeaderField: "a"), "1")
        XCTAssertEqual(task.originalRequest!.value(forHTTPHeaderField: "b"), "2")
    }
}
