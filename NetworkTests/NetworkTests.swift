//
//  OperationTests.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import XCTest
import OHHTTPStubs
import SQKResult
@testable import Network

class NetworkTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
    
    
    func testResponseValidation() {
        
        let success = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        switch URLSession.shared.valid(response: success, error: nil) {
        case .ok:
            break
        default:
            XCTFail()
        }
        
        let serverFail = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
        switch URLSession.shared.valid(response: serverFail, error: nil) {
        case .server(let response):
            XCTAssertEqual(response.statusCode, 500)
            break
        default:
            XCTFail()
        }
        
        let notFound = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        switch URLSession.shared.valid(response: notFound, error: nil) {
        case .server(let response):
            XCTAssertEqual(response.statusCode, 404)
            break
        default:
            XCTFail()
        }
        
        let authentication = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 401, httpVersion: "1.1", headerFields: nil)
        switch URLSession.shared.valid(response: authentication, error: nil) {
        case .needsAuthentication:
            break
        default:
            XCTFail()
        }
        
        
        let error = NSError(domain: "Hello", code: 1, userInfo: nil)
        switch URLSession.shared.valid(response: nil, error: error) {
        case .device(let anError as NSError):
            XCTAssertEqual(anError, error)
            break
        default:
            XCTFail()
        }
    }
    
    
    func testNetworkOperationFailure() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(BlockRequestable {
            return URLRequest(url: URL(string: "http://google.com")!)
        })
        
        
        networkOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case ServerError.unknown(_):
                    expect.fulfill()
                default:
                    XCTFail()
                }
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
        

        let networkOperation = URLResponseOperation(BlockRequestable {
            return URLRequest(url: URL(string: "http://google.com")!)
        })
        
        
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
    
    func testDependancies() {
        let expect = expectation(description: "")
        
        let trueOperation = BlockResultOperation {
            return true
        }
        
        let negatingOperation = MapResultOperation<Bool, Bool> { previous in
            do {
                let boolean = try previous.resolve()
                return Result { return !boolean }
            } catch {
                return Result { throw error }
            }
        }
        
        negatingOperation.addResultBlock { result in
            do {
                let boolean = try result.resolve()
                XCTAssertFalse(boolean)
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        trueOperation.then(do: negatingOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testMultipleResultBlocks() {
        let expect1 = expectation(description: "")
        let expect2 = expectation(description: "")

        let operation = BlockResultOperation {
            return true
        }
        
        operation.addResultBlock { result in
            expect1.fulfill()
        }
        
        operation.addResultBlock { result in
            expect2.fulfill()
        }
        
        operation.enqueue()
        
        waitForExpectations(timeout: 1)
    }

    
    func testNetworkOperationFailureWithRetry() {
        let _ = stub(condition: isHost("google.com")) { _ -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(jsonObject: [:], statusCode: 500, headers: [:])
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(BlockRequestable {
            return URLRequest(url: URL(string: "http://google.com")!)
        })
        
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
