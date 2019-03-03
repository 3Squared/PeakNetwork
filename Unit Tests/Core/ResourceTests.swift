//
//  ResourceTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 03/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation
import PeakResult
#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class ResourceTests: XCTestCase {

    func testGet() {
        let resources = WebService()
        let resource = resources.simple()
        
        XCTAssertEqual(resource.request.url!.absoluteString, "https://example.com/all?token=hello")
        XCTAssertEqual(resource.request.value(forHTTPHeaderField: "user-agent")!, "peaknetwork")
    }

    func testPost() {
        let resources = WebService()
        let resource = resources.complex(TestEntity(name: "sam"))
        
        let request = resource.request
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        
        XCTAssertEqual(components.queryItems!.count, 2)
        XCTAssertTrue(components.queryItems!.contains { $0.name == "search" && $0.value == "test"})
        XCTAssertTrue(components.queryItems!.contains { $0.name == "token" && $0.value == "overridden"})

        XCTAssertEqual(request.allHTTPHeaderFields!.count, 2)
        XCTAssertEqual(request.value(forHTTPHeaderField: "user-agent")!, "overridden")
        XCTAssertEqual(request.value(forHTTPHeaderField: "device")!, "iphone")
        XCTAssertEqual(String(data: request.httpBody!, encoding: .utf8)!, "{\"name\":\"sam\"}")
    }
}
