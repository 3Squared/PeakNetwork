//
//  ResourceTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 03/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class ResourceTests: XCTestCase {


    func test_test() {
        let endpoint = Endpoint(baseURL: "https://example.com", path: "test", query: [:], customise: nil)

        let resource = Resource(endpoint: endpoint, headers: [:], method: .get) { data in
            
        }
        
        XCTAssertEqual(resource.request.url!.absoluteString, "https://example.com/test")
    }
}

