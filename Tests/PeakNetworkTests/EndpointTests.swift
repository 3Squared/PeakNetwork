//
//  EndpointTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 11/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation
@testable import PeakNetwork

class EndpointTests: XCTestCase {

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
    
    func test_BaseURL_MultipleQueryItemsWithSameName_CreatesValidURL() {
        let endpoint = Endpoint(
            baseURL: URL("https://example.com/"),
            path: "test",
            queryItems: [
                URLQueryItem(name: "param", value: "1"),
                URLQueryItem(name: "param", value: "2")
            ],
            customise: nil
        )
        XCTAssertEqual(endpoint.url.absoluteString, "https://example.com/test?param=1&param=2")
    }
}
