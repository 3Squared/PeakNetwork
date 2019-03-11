//
//  EndpointTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 11/03/2019.
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

class EndpointTests: XCTestCase {
    
    func test_BaseURLWithoutTrailingSlash_PathWithoutLeadingSlash_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: "https://example.com", path: "test", query: [:], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test")
    }
    
    func test_BaseURLWithoutTrailingSlash_PathWithLeadingSlash_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: "https://example.com", path: "/test", query: [:], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test")
    }
    
    func test_BaseURLWithTrailingSlash_PathWithoutLeadingSlash_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: "https://example.com/", path: "test", query: [:], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test")
    }
    
    func test_BaseURLWithTrailingSlash_PathWithLeadingSlash_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: "https://example.com/", path: "/test", query: [:], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test")
    }
    
    func test_BaseURLWithPathComponent_IsCombinedWithPath() {
        let endpoint = Endpoint(baseURL: "https://example.com/test", path: "example", query: [:], customise: nil)
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test/example")
    }
    
    func test_CustomisingComponents_CreatesValidURL() {
        let endpoint = Endpoint(baseURL: "https://example.com", path: "test", query: [:]) { components in
            components.scheme = "ftp"
        }
        XCTAssertEqual(endpoint.url.absoluteString, "ftp://example.com/test")
    }
}
