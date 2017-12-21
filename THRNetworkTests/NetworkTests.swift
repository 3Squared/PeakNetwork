//
//  OperationTests.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import XCTest
import OHHTTPStubs
import THRResult
@testable import THRNetwork

class NetworkTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
    
    
    func testResponseValidation() {
        let success = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(success!.statusCodeEnum.isSuccess)
        
        let serverFail = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(serverFail!.statusCodeEnum.isServerError)

        
        let notFound = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(notFound!.statusCodeEnum.isClientError)
        
        let authentication = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 401, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(authentication!.statusCodeEnum.isClientError)
        XCTAssertTrue(authentication!.statusCodeEnum == .unauthorized)
    }
    
    
    func testNetworkOperationFailure() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(URLRequestable(URL(string: "http://google.com")!))
        
        networkOperation.addResultBlock { result in
            switch result {
            case .failure(ServerError.error(code: .internalServerError, response: _)):
                expect.fulfill()
            default:
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperationSuccess() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: [:])
        }
        
        let expect = expectation(description: "")

        let networkOperation = URLResponseOperation(URLRequestable(URL(string: "http://google.com")!))
        
        networkOperation.addResultBlock { result in
            do {
                let response = try result.resolve()
                XCTAssertEqual(response.statusCode, 200)
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testRequestOperationParseSuccess() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: ["name" : "Sam"], statusCode: 200, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<TestEntity>(URLRequestable(URL(string: "http://google.com")!))
        
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
    
    func testRequestOperationParseFailure() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: ["wrong" : "key"], statusCode: 200, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<TestEntity>(URLRequestable(URL(string: "http://google.com")!))
        
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

    
    func testManyRequestOperationParseSuccess() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [["name" : "Sam"], ["name" : "Ben"]], statusCode: 200, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<[TestEntity]>(URLRequestable(URL(string: "http://google.com")!))
        
        networkOperation.addResultBlock { result in
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
        
        networkOperation.enqueue()
    
        waitForExpectations(timeout: 1)
    }
    
    func testManyOperationParseFailure() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [["wrong" : "key"], ["name" : "Ben"]], statusCode: 200, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<[TestEntity]>(URLRequestable(URL(string: "http://google.com")!))
        
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
    
    func testNetworkOperationFailureWithRetry() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(URLRequestable(URL(string: "http://google.com")!))
        
        var runCount = 0
        networkOperation.retryStrategy = { failureCount in
            runCount += 1
            return failureCount < 3
        }
        
        networkOperation.addResultBlock { result in
            XCTAssertEqual(runCount, 3)
            expect.fulfill()
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 100)
    }

    public enum TestError: Error {
        case justATest
    }
}
