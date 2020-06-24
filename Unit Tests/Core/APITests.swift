//
//  APITests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 12/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class APITests: XCTestCase {
    
    func test_SimpleAPI_CreatesCorrectRequest() {
        let api = SimpleAPI()
        let resource: Resource<Void> = api.resource(.get, path: "test")
        
        XCTAssertEqual(resource.request.url!.absoluteString, "https://simple.com/test")
        XCTAssertTrue(resource.request.allHTTPHeaderFields!.isEmpty)
    }

    func test_GET_FromAPIWithCommonFields_CreatesCorrectRequest() {
        let api = MyAPI()
        let resource = api.simple()

        XCTAssertEqual(resource.request.url!.absoluteString, "https://example.com/all?token=hello")
        XCTAssertEqual(resource.request.value(forHTTPHeaderField: "user-agent")!, "peaknetwork")
    }
    
    func test_GET_FromAPIWithNonUniqueQueryParams_CreatesCorrectRequest() {
        let api = MyAPI()
        let resource = api.queryParams([
            URLQueryItem(name: "param", value: "1"),
            URLQueryItem(name: "param", value: "2")
        ])
        
        XCTAssertEqual(resource.request.url!.absoluteString, "https://example.com/query?param=1&param=2&token=hello")
    }
    
    func test_POST_FromAPIWithCommonFields_CreatesCorrectRequest() {
        let api = MyAPI()
        let resource = api.complex(TestEntity(name: "sam"))
        
        let request = resource.request
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        
        XCTAssertEqual(components.queryItems!.count, 2)
        XCTAssertTrue(components.queryItems!.contains { $0.name == "search" && $0.value == "test"})
        
        XCTAssertEqual(request.allHTTPHeaderFields!.count, 2)
        XCTAssertEqual(request.value(forHTTPHeaderField: "user-agent")!, "overridden")
        XCTAssertEqual(request.value(forHTTPHeaderField: "device")!, "iphone")
        XCTAssertEqual(String(data: request.httpBody!, encoding: .utf8)!, "{\"name\":\"sam\"}")
    }
    
    func test_SimpleAPI_CreatesConfiguredOperation() {
        let api = SimpleAPI()
        let resource: Resource<Void> = api.resource(.get, path: "test")
        let operation = api.operation(for: resource)
        
        let input = try! operation.input.get()
        XCTAssertEqual(operation.session as! URLSession, api.session as! URLSession)
        XCTAssertEqual(input.request.url!.absoluteString, "https://simple.com/test")
    }
}

struct SimpleAPI: WebAPI {
    let baseURL = URL("https://simple.com/")
}
