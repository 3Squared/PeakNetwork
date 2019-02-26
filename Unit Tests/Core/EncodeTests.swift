//
//  EncodeTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 21/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakResult
import PeakOperation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class EncodeTests: XCTestCase {
    
    func testJSONEncodeOperationEncodesToData() {
        let object = TestEntity(name: "Test")
        let encode = JSONEncodeOperation<TestEntity>(input: object)
        
        let expect = expectation(description: #function)
        encode.addResultBlock { _ in
            expect.fulfill()
        }
        encode.enqueue()
        waitForExpectations(timeout: 1)
        
        let data = try! encode.output.resolve()
        let string = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(string, "{\"name\":\"Test\"}")
    }
    
    func testJSONEncodeArrayOperationEncodesToArrayOfData() {
        let objects = [
            TestEntity(name: "Test_1"),
            TestEntity(name: "Test_2")
        ]
        
        let encode = JSONEncodeArrayOperation<TestEntity>(input: objects)
        
        let expect = expectation(description: #function)
        encode.addResultBlock { _ in
            expect.fulfill()
        }
        encode.enqueue()
        waitForExpectations(timeout: 1)
        
        let datas = try! encode.output.resolve()
        let first = String(data: datas[0], encoding: .utf8)
        let second = String(data: datas[1], encoding: .utf8)

        XCTAssertEqual(first, "{\"name\":\"Test_1\"}")
        XCTAssertEqual(second, "{\"name\":\"Test_2\"}")
    }

}
