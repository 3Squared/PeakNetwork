//
//  EndpointTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 11/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class EndpointTests: XCTestCase {
    
    func test_MergeURLQueryItems() {
        let one = ["hello": "world", "shared": "one"].queryItems
        let two = ["goodbye": "moon", "shared": "two"].queryItems
        
        let mergedA = one.merging(two) { _, new  in
            return new
        }
        
        XCTAssertEqual(mergedA.count, 3)
        XCTAssertEqual(mergedA.first { $0.name == "shared"}!.value!, "two")

        let mergedB = one.merging(two) { current, _  in
            return current
        }
        
        XCTAssertEqual(mergedB.count, 3)
        XCTAssertEqual(mergedB.first { $0.name == "shared"}!.value!, "one")
    }
        
    func test_BaseURLWithTrailingSlash_PathWithoutLeadingSlash_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: URL("https://example.com/"), path: "test", queryItems: [], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test")
    }
        
    func test_BaseURLWithPathComponent_IsCombinedWithPath() {
        let endpoint = Endpoint(baseURL: URL("https://example.com/test/"), path: "example", queryItems: [], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test/example")
    }
    
    func test_CustomisingComponents_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: URL("https://example.com/"), path: "test", queryItems: []) { components in
            components.scheme = "ftp"
        }
        XCTAssertEqual(endpoint.url.absoluteString, "ftp://example.com/test")
    }
    
    func test_BaseURL_QueryItems_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: URL("https://example.com/"), path: "test", queryItems: ["hello": "world"].queryItems, customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test?hello=world")
    }
}
