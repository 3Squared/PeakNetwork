//
//  NetworkTests.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import XCTest
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
        XCTAssertTrue(success!.statusCodeValue.isSuccess)
        
        let serverFail = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(serverFail!.statusCodeValue.isServerError)

        let notFound = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(notFound!.statusCodeValue.isClientError)
        
        let authentication = HTTPURLResponse(url: URL(string:"google.com")!, statusCode: 401, httpVersion: "1.1", headerFields: nil)
        XCTAssertTrue(authentication!.statusCodeValue.isClientError)
        XCTAssertTrue(authentication!.statusCodeValue == .unauthorized)
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
                let response = try result.get()
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
                let response = try result.get()
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
                let entity = try result.get()
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
                let _ = try result.get()
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
        
        XCTAssertEqual(try! networkOperation.output.get().name, "Sam")
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
    
    func testNetworkOperation_PassingBody_OnlyPassesTheParsedData() {
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["name" : "Sam"], statusCode: .ok))
        }

        let expect = expectation(description: "")
        let networkOperation = NetworkOperation(resource: api.simple(), session: session)

        let mapOperation = BlockMapOperation<TestEntity, Void> { input in
            do {
                let entity = try input.get()
                XCTAssertEqual(entity.name, "Sam")
                expect.fulfill()
            } catch {
                XCTFail()
            }
            return .success(())
        }
        
        networkOperation.passesBody(to: mapOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    func testNetworkOperation_PassingBody_PassesFailure() {
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let expect = expectation(description: "")
        let networkOperation = NetworkOperation(resource: api.simple(), session: session)
        
        let mapOperation = BlockMapOperation<TestEntity, Void> { input in
            do {
                _ = try input.get()
                XCTFail()
            } catch {
                expect.fulfill()
            }
            return .success(())
        }
        
        networkOperation.passesBody(to: mapOperation).enqueue()
        
        waitForExpectations(timeout: 1)
    }
    
    public enum TestError: Error {
        case justATest
    }
}
