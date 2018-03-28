//
//  OperationTests.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import XCTest
import THRResult
@testable import THRNetwork

class NetworkTests: XCTestCase {
    
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
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }

        let request = URLRequestable(URL(string: "http://google.com")!)

        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(request, session: session)
        
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
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
        }

        let expect = expectation(description: "")

        let networkOperation = URLResponseOperation(URLRequestable(URL(string: "http://google.com")!), session: session)
        
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
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<TestEntity>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let (entity, _) = try result.resolve()
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
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["wrong" : "key"], statusCode: .ok))
        }

        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<TestEntity>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
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

    
    func testRequestOperationWithHeadersParseSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok, responseHeaders: ["hello": "World!"]))
        }

        
        let expect = expectation(description: "")
        
        let networkOperation = RequestWithHeadersOperation<TestEntity, Headers>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let (entity, headers, _) = try result.resolve()
                
                XCTAssertEqual(entity.name, "Sam")
                XCTAssertEqual(headers.hello, "World!")
                
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }

    
    func testRequestOperationWithHeadersParseFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok, responseHeaders: ["missing": "key"]))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestWithHeadersOperation<TestEntity, Headers>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case TestError.justATest:
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
        let session = MockSession { session in
            session.queue(response: MockResponse(json: [["name" : "Sam"], ["name" : "Ben"]], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<[TestEntity]>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let (entities, _) = try result.resolve()
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
        let session = MockSession { session in
            session.queue(response: MockResponse(json: [["wrong" : "key"], ["name" : "Ben"]], statusCode: .ok))
        }

        
        let expect = expectation(description: "")
        
        let networkOperation = RequestOperation<[TestEntity]>(URLRequestable(URL(string: "http://google.com")!), session: session)
        
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
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .internalServerError, sticky: true))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = URLResponseOperation(URLRequestable(URL(string: "http://google.com")!), session: session)
        
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
    
    func testFileRequestOperation() {
        let expect = expectation(description: "")
        
        let networkOperation = FileRequestOperation<[TestEntity]>(withFileName: "test")
        
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

    func testFileRequestOperationError() {
        let expect = expectation(description: "")
        
        let networkOperation = FileRequestOperation<[TestEntity]>(withFileName: "test", error: ServerError.unknownResponse)
        
        networkOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                XCTAssertTrue(error.localizedDescription.contains("THRNetwork.ServerError error"))
                expect.fulfill()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }

    public struct Headers: HTTPHeaders {
        
        let hello: String
        public init(withHeaders headers: [AnyHashable : Any]) throws {
            guard let hello = headers["hello"] as? String else {
                throw TestError.justATest
            }
            self.hello = hello
        }

        
    }

    public enum TestError: Error {
        case justATest
    }
}
