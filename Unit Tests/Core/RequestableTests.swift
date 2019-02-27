//
//  RequestableTests.swift
//  PeakNetwork-iOSTests
//
//  Created by Sam Oakley on 21/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import XCTest
import PeakOperation
import PeakResult
#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

class RequestableTests: XCTestCase {
    
    func test_getRequestStructWithAllParameters_isConvertedToValidRequest() {
        let request = Request("https://example.com",
                              path: "test",
                              query: ["hello" : "world"],
                              headers: ["goodbye": "moon"],
                              method: .get).request
        
        XCTAssertEqual(request.url!.absoluteString, "https://example.com/test?hello=world")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.allHTTPHeaderFields!, ["goodbye" : "moon"])
        XCTAssertEqual(request.httpMethod!, "GET")
    }
    
    
    func test_postRequestStructWithMinimalParameters_isConvertedToValidRequest() {
        let request = Request("https://example.com",
                              path: "test",
                              method: .post).request
        
        XCTAssertEqual(request.url!.absoluteString, "https://example.com/test")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
        XCTAssertEqual(request.httpMethod!, "POST")
    }

    
    func test_bodyRequest_isConvertedToValidRequest() {
        let encoder = JSONEncoder()
        let request = BodyRequest("https://example.com",
                              path: "test",
                              body: TestEntity(name: "Sam"),
                              method: .put,
                              encoder: encoder).request
        
        XCTAssertEqual(request.url!.absoluteString, "https://example.com/test")
        XCTAssertEqual(String(data: request.httpBody!, encoding: .utf8)!, "{\"name\":\"Sam\"}")
        XCTAssertEqual(request.allHTTPHeaderFields, [:])
        XCTAssertEqual(request.httpMethod!, "PUT")
    }
    
    
    func test_multipleBodyRequestNetworkOperation_returnsSuccessfulObjects() {
        // Arrange:
        let encoder = JSONEncoder()
        let session = MockSession { session in
            session.queue(response: MockResponse(sticky: true))
        }
        
        let entities = [
            TestEntity(name: "Sam"),
            TestEntity(name: "Ben"),
            TestEntity(name: "Luke")
        ]

        // Act:
        let map = CodableToRequestOperation(input: entities, encoder: encoder)
        let operation = MultipleBodyRequestNetworkOperation<TestEntity>(session: session)
        
        let expect = expectation(description: "")
        operation.addResultBlock { outcome in
            expect.fulfill()
        }
        
        map.passesResult(to: operation).enqueue()
        
        waitForExpectations(timeout: 100)

        // Assert:
        switch operation.output {
        case .success(let outcomes):
            XCTAssertEqual(outcomes.successes.count, 3)
            XCTAssertEqual(outcomes.failures.count, 0)
            
            // order of outcomes is not guaranteed
            XCTAssertTrue(outcomes.successes.contains { $0.object.name == "Sam" })
            XCTAssertTrue(outcomes.successes.contains { $0.object.name == "Ben" })
            XCTAssertTrue(outcomes.successes.contains { $0.object.name == "Luke" })
        case .failure(_):
            XCTFail()
        }
    }
    
    func test_multipleBodyRequestNetworkOperation_returnsSuccessesAndFailures() {
        // Arrange:
        let encoder = JSONEncoder()
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
            session.queue(response: MockResponse(statusCode: .unauthorized))
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let entities = [
            TestEntity(name: "Sam"),
            TestEntity(name: "Ben"),
            TestEntity(name: "Luke")
        ]
        
        // Act:
        let map = CodableToRequestOperation(input: entities, encoder: encoder)
        let operation = MultipleBodyRequestNetworkOperation<TestEntity>(session: session)
        
        let expect = expectation(description: "")
        operation.addResultBlock { outcome in
            expect.fulfill()
        }
        
        map.passesResult(to: operation).enqueue()
        
        waitForExpectations(timeout: 6)
        
        // Assert:
        switch operation.output {
        case .success(let outcomes):
            XCTAssertEqual(outcomes.successes.count, 1)
            XCTAssertEqual(outcomes.failures.count, 2)
            
            // order of outcomes is not guaranteed
            XCTAssertTrue(outcomes.failures.contains {
                if case ServerError.error(code: .unauthorized, _,  _) = $0.error {
                    return true
                } else {
                    return false
                }
            })
            
            XCTAssertTrue(outcomes.failures.contains {
                if case ServerError.error(code: .internalServerError, _,  _) = $0.error {
                    return true
                } else {
                    return false
                }
            })

        case .failure(_):
            XCTFail()
        }
    }
    
    func test_multipleRequestNetworkOperation_returnsSuccessesAndFailures() {
        // Arrange:
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
            session.queue(response: MockResponse(statusCode: .unauthorized))
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let requests: [Requestable] = [
            TestRequests.get(named: "Sam"),
            TestRequests.get(named: "Ben"),
            TestRequests.get(named: "Luke")
        ]
        
        // Act:
        let operation = MultipleRequestNetworkOperation(requestables: requests, session: session)
        
        let expect = expectation(description: "")
        operation.addResultBlock { outcome in
            expect.fulfill()
        }
        
        operation.enqueue()
        
        waitForExpectations(timeout: 6)
        
        // Assert:
        switch operation.output {
        case .success(let outcomes):
            XCTAssertEqual(outcomes.successes.count, 1)
            XCTAssertEqual(outcomes.failures.count, 2)
            
            // order of outcomes is not guaranteed
            XCTAssertTrue(outcomes.failures.contains {
                if case ServerError.error(code: .unauthorized, _,  _) = $0 {
                    return true
                } else {
                    return false
                }
            })
            
            XCTAssertTrue(outcomes.failures.contains {
                if case ServerError.error(code: .internalServerError, _,  _) = $0 {
                    return true
                } else {
                    return false
                }
            })
            
        case .failure(_):
            XCTFail()
        }
    }


}

class CodableToRequestOperation: MapOperation<[TestEntity], [BodyRequest<TestEntity>]> {
    
    let encoder: JSONEncoder
    
    init(input: Input?, encoder: JSONEncoder) {
        self.encoder = encoder
        super.init(input: input)
    }
    
    override func map(input: [TestEntity]) -> Result<[BodyRequest<TestEntity>]> {
        return .success(input.map { TestRequests.upload($0, encoder: encoder) })
    }
}

struct TestRequests {
    
    static let baseURL = "https://example.com"

    static func get(named name: String) -> Request {
        return Request(baseURL,
                           path: "upload",
                           query: ["name": name],
                           headers: headers,
                           method: .get)
    }

    
    static func upload(_ entity: TestEntity, encoder: JSONEncoder) -> BodyRequest<TestEntity> {
        return BodyRequest(baseURL,
                           path: "upload",
                           body: entity,
                           headers: headers,
                           method: .post,
                           encoder: encoder)
    }
    
    static var headers: [String: String] {
        return [
            "apiKey": "hello",
            "apiVersion": "1",
        ]
    }
}
