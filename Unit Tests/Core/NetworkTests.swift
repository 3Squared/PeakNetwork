//
//  NetworkTests.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import XCTest
import PeakResult
import PeakOperation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class NetworkTests: XCTestCase {
    
    let api = MyAPI()
    
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

        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(resource: api.simple(), session: session)
        
        networkOperation.addResultBlock { result in
            switch result {
            case .failure(ServerError.error(code: .internalServerError, data: _, response: _)):
                expect.fulfill()
            default:
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperationFailureWithResponseBody() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["hello": "world"], statusCode: .internalServerError))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(resource: api.simple(), session: session)

        networkOperation.addResultBlock { result in
            switch result {
            case .failure(ServerError.error(code: .internalServerError, data: let data, response: _)):
                let responseString = String(data: data!, encoding: .utf8)
                XCTAssertEqual("{\"hello\":\"world\"}", responseString)
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
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }

        let expect = expectation(description: "")

        let networkOperation = NetworkOperation(resource: api.simple(), session: session)

        networkOperation.addResultBlock { result in
            do {
                let response = try result.resolve()
                XCTAssertEqual(response.urlResponse.statusCode, 200)
                expect.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperation_BodyAndResponse_Success() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(resource: api.complexWithResponse(TestEntity(name: "Test")), session: session)
        
        networkOperation.addResultBlock { result in
            do {
                let response = try result.resolve()
                XCTAssertEqual(response.parsed.name, "Sam")
                expect.fulfill()
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperationInputSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation<TestEntity>(session: session)

        networkOperation.input = Result { api.simple() }
        
        networkOperation.addResultBlock { result in
            do {
                let entity = try result.resolve()
                XCTAssertEqual(entity.parsed.name, "Sam")
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperationWithNoInputFailure() {
        let session = MockSession { _ in }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation<TestEntity>(session: session)

        networkOperation.addResultBlock { result in
            do {
                let _ = try result.resolve()
                XCTFail()
            } catch {
                switch error {
                case ResultError.noResult:
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
        
        let networkOperation = NetworkOperation(resource: api.simple(), session: session)

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
    
    func testNetworkOperation_voidResponse() {
        let session = MockSession { session in
            session.queue(response: MockResponse())
        }
        
        let networkOperation = NetworkOperation(resource: api.complex(TestEntity(name: "sam")), session: session)

        let expect = expectation(description: "")
        networkOperation.addResultBlock { _ in
            expect.fulfill()
        }
        
        networkOperation.enqueue()
        waitForExpectations(timeout: 10)
        
        switch networkOperation.output {
        case .success(let response):
            XCTAssertNotNil(response.parsed)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMultipleResourceNetworkOperation_allSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name": "sam"]) { $0.url!.absoluteString.contains("sam") })
            session.queue(response: MockResponse(json: ["name": "ben"]) { $0.url!.absoluteString.contains("ben") })
        }

        let networkOperation = MultipleResourceNetworkOperation(identifiableResources: [
            (1, api.resource(path: "/sam", method: .get) as Resource<TestEntity>),
            (2, api.resource(path: "/ben", method: .get) as Resource<TestEntity>)
        ], session: session)
        
        let expect = expectation(description: "")
        networkOperation.addResultBlock { _ in
            expect.fulfill()
        }
        
        networkOperation.enqueue()
        waitForExpectations(timeout: 10)
        
        let outcomes = try! networkOperation.output.resolve()
        XCTAssertEqual(outcomes.successes.count, 2)
        XCTAssertTrue(outcomes.successes.contains {
             $0.object == 1 && $0.response.parsed.name == "sam"
        })
        XCTAssertTrue(outcomes.successes.contains {
            $0.object == 2 && $0.response.parsed.name == "ben"
        })
    }
    
    func testMultipleResourceNetworkOperation_voidBody_withFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name": "sam"]))
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let networkOperation = MultipleResourceNetworkOperation(resources: [
            api.simple(),
            api.simple()
        ], session: session)
        
        let expect = expectation(description: "")
        networkOperation.addResultBlock { _ in
            expect.fulfill()
        }
        
        networkOperation.enqueue()
        waitForExpectations(timeout: 10)
        
        let outcomes = try! networkOperation.output.resolve()
        XCTAssertEqual(outcomes.successes.count, 1)
        XCTAssertEqual(outcomes.successes[0].response.parsed.name, "sam")
        XCTAssertTrue(outcomes.successes[0].object == ())
        XCTAssertEqual(outcomes.failures.count, 1)
    }

    func testMultipleResourceNetworkOperation_voidBody_allSuccess() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name": "sam"]))
            session.queue(response: MockResponse(json: ["name": "ben"]))
        }
        
        let networkOperation = MultipleResourceNetworkOperation(resources: [
            api.simple(),
            api.simple()
        ], session: session)
        
        let expect = expectation(description: "")
        networkOperation.addResultBlock { _ in
            expect.fulfill()
        }
        
        networkOperation.enqueue()
        waitForExpectations(timeout: 10)
        
        let outcomes = try! networkOperation.output.resolve()
        XCTAssertEqual(outcomes.successes.count, 2)
        XCTAssertTrue(outcomes.successes.contains { $0.response.parsed.name == "sam" })
        XCTAssertTrue(outcomes.successes.contains { $0.response.parsed.name == "ben" })
    }
    
    func testNetworkOperation_UnwrappingSuccess_GivesSuccessfullyParsedData() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }
        
        let expect = expectation(description: "")
        
        let networkOperation = NetworkOperation(resource: api.simple(), session: session).unwrapped
        
        networkOperation.addResultBlock { result in
            expect.fulfill()
        }
        networkOperation.enqueue()
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(try! networkOperation.output.resolve().name, "Sam")
    }
    
    
    func testNetworkOperation_UnwrappingFailure_GivesFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let expect = expectation(description: "")
        let networkOperation = NetworkOperation(resource: api.simple(), session: session).unwrapped
        networkOperation.enqueue { result in
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        switch networkOperation.output {
        case .failure(ServerError.error(code: .internalServerError, data: _, response: _)):
            break
        default:
            XCTFail()
        }
    }
    
    
    public enum TestError: Error {
        case justATest
    }
}
