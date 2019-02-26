//
//  DecodeTests.swift
//  PeakNetwork-iOS
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

class DecodeTests: XCTestCase {
    
    func testNetworkThenDecodeOperationParseSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(requestable: URL(string: "http://google.com")!, session: session)
        let decodeOperation = JSONDecodeOperation<TestEntity>()
        
        decodeOperation.addResultBlock { result in
            do {
                let entity = try result.resolve()
                XCTAssertEqual(entity.name, "Sam")
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.passesResult(to: decodeOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkThenDecodeOperationParseFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["wrong" : "key"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(requestable: URL(string: "http://google.com")!, session: session)
        let decodeOperation = JSONDecodeOperation<TestEntity>()
        
        decodeOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case DecodingError.keyNotFound(_, _):
                    expect.fulfill()
                default:
                    XCTFail()
                }
            }
        }
        
        networkOperation.passesResult(to: decodeOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    
    func testNetworkThenDecodeArrayOperationParseSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: [["name" : "Sam"], ["name" : "Ben"]], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(requestable: URL(string: "http://google.com")!, session: session)
        let decodeOperation = JSONDecodeOperation<[TestEntity]>()
        
        decodeOperation.addResultBlock { result in
            do {
                let entities = try result.resolve()
                XCTAssertEqual(entities.count, 2)
                XCTAssertEqual(entities[0].name, "Sam")
                XCTAssertEqual(entities[1].name, "Ben")
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.passesResult(to: decodeOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkThenDecodeArrayOperationParseFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: [["wrong" : "key"], ["name" : "Ben"]], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(requestable: URL(string: "http://google.com")!, session: session)
        let decodeOperation = JSONDecodeOperation<[TestEntity]>()
        
        decodeOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case DecodingError.keyNotFound(_, _):
                    expect.fulfill()
                default:
                    XCTFail()
                }
            }
        }
        
        networkOperation.passesResult(to: decodeOperation).enqueue()
        waitForExpectations(timeout: 1)
    }
    
    func testFileRequestOperation() {
        let expect = expectation(description: "")
        
        let networkOperation = DecodableFileOperation<[TestEntity]>(withFileName: "test")
        
        networkOperation.addResultBlock { result in
            do {
                let entity = try result.resolve()
                XCTAssertEqual(entity[0].name, "Hello")
                XCTAssertEqual(entity[1].name, "World")
                XCTAssertEqual(entity[2].name, "!")
                XCTAssertEqual(entity.count, 3)
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testDecodableOperationParseSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = DecodableOperation<TestEntity>(requestable: URL(string: "http://google.com")!, session: session)
        networkOperation.addResultBlock { result in
            do {
                let entity = try result.resolve()
                XCTAssertEqual(entity.name, "Sam")
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    
    func testDecodableOperationParseFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["wrong" : "key"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = DecodableOperation<TestEntity>(requestable: URL(string: "http://google.com")!, session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case DecodingError.keyNotFound(_, _):
                    expect.fulfill()
                default:
                    XCTFail()
                }
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    
    func testDecodableResponseOperationParseSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = DecodableResponseOperation<TestEntity>(requestable: URL(string: "http://google.com")!, session: session)
        networkOperation.addResultBlock { result in
            do {
                let (entity, response) = try result.resolve()
                XCTAssertEqual(entity.name, "Sam")
                XCTAssertEqual(response.statusCodeEnum, .ok)
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }

    public enum TestError: Error {
        case justATest
    }
}
