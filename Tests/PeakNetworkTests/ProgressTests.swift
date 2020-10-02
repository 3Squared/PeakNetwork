//
//  ProgressTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 11/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation
@testable import PeakNetwork

class ProgressTests: XCTestCase {
    
    func testNetworkOperationUsesTaskProgress() {
        
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }

        let resource = Resource<Void>(method: .get, url: URL(string: "http://example.com")!, headers: [:])

        let networkOperation = NetworkOperation(resource: resource, session: session)
        
        let progress = networkOperation.chainProgress()
        
        keyValueObservingExpectation(for: progress, keyPath: "fractionCompleted") {  observedObject, change in
            return progress.completedUnitCount >= progress.totalUnitCount
        }
        
        networkOperation.enqueue()
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual(progress.fractionCompleted, 1)
    }
    
}
