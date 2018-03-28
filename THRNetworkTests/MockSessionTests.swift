//
//  MockSessionTests.swift
//  THRNetworkTests
//
//  Created by Sam Oakley on 28/03/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

import XCTest
@testable import THRNetwork

class MockSessionTests: XCTestCase {

    func testQueuingOfResponsesForSameURL()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 2

        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok))
            session.queue(response: MockResponse(statusCode: .internalServerError))
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        
        session.dataTask(with: request) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCode == 200)
            expect.fulfill()
        }.resume()
        
        session.dataTask(with: request) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCode == 500)
            expect.fulfill()
        }.resume()

        
        waitForExpectations(timeout: 1)
    }
    
    func testQueuingOfResponsesForDifferentURLs()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 4
        
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok) { $0.url?.host == "google.com" })
            session.queue(response: MockResponse(statusCode: .accepted) { $0.url?.host == "google.com" })
            session.queue(response: MockResponse(statusCode: .alreadyReported) { $0.url?.host == "reddit.com" })
            session.queue(response: MockResponse(statusCode: .badGateway) { $0.url?.host == "reddit.com" })
        }
        
        let googleRequest = URLRequest(url: URL(string: "http://google.com")!)
        let redditRequest = URLRequest(url: URL(string: "http://reddit.com")!)

        session.dataTask(with: googleRequest) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCodeEnum == .ok)
            expect.fulfill()
        }.resume()
        
        session.dataTask(with: redditRequest) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCodeEnum == .alreadyReported)
            expect.fulfill()
        }.resume()
        
        session.dataTask(with: googleRequest) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCodeEnum == .accepted)
            expect.fulfill()
        }.resume()
        
        session.dataTask(with: redditRequest) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCodeEnum == .badGateway)
            expect.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 1)
    }

    func testQueuingOfStickyResponse()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 4
        
        let session = MockSession { session in
            session.queue(response: MockResponse(statusCode: .ok, sticky: true) { $0.url?.host == "google.com" })
        }
        
        let googleRequest = URLRequest(url: URL(string: "http://google.com")!)
        
        let task = session.dataTask(with: googleRequest) { data, response, error in
            XCTAssert((response as! HTTPURLResponse).statusCodeEnum == .ok)
            expect.fulfill()
        }
        
        task.resume()
        task.resume()
        task.resume()
        task.resume()
        
        waitForExpectations(timeout: 1)
    }
    
    func testMockResponseIsLoadedFromJsonFile()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 1
        
        let session = MockSession { session in
            session.queue(response: MockResponse(fileName: "test", statusCode: .ok))
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        
        session.dataTask(with: request) { data, response, error in
            let json = try! JSONDecoder().decode([[String: String]].self, from: data!)
            XCTAssert(json.count == 3)
            XCTAssert(json[0]["name"] == "Hello")
            XCTAssert(json[1]["name"] == "World")
            XCTAssert(json[2]["name"] == "!")
            expect.fulfill()
        }.resume()
        
        waitForExpectations(timeout: 1)
    }
    
    func testMockResponseUsingArray()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 1
        
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["one", "two"], statusCode: .ok))
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        
        session.dataTask(with: request) { data, response, error in
            let json = try! JSONDecoder().decode([String].self, from: data!)
            XCTAssert(json.count == 2)
            XCTAssert(json[0] == "one")
            XCTAssert(json[1] == "two")
            expect.fulfill()
            }.resume()
        
        waitForExpectations(timeout: 1)
    }
    
    func testMockResponseUsingDictionary()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 1
        
        let session = MockSession { session in
            session.queue(response: MockResponse(json: ["one": "two"], statusCode: .ok))
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        
        session.dataTask(with: request) { data, response, error in
            let json = try! JSONDecoder().decode([String: String].self, from: data!)
            XCTAssert(json.keys.count == 1)
            XCTAssert(json["one"] == "two")
            expect.fulfill()
            }.resume()
        
        waitForExpectations(timeout: 1)
    }

    func testMockResponseUsingString()  {
        let expect = expectation(description: "")
        expect.expectedFulfillmentCount = 1
        
        let session = MockSession { session in
            session.queue(response: MockResponse(jsonString: "{ \"one\": \"two\" }", statusCode: .ok))
        }
        
        let request = URLRequest(url: URL(string:"http://google.com")!)
        
        session.dataTask(with: request) { data, response, error in
            let json = try! JSONDecoder().decode([String: String].self, from: data!)
            XCTAssert(json.keys.count == 1)
            XCTAssert(json["one"] == "two")
            expect.fulfill()
            }.resume()
        
        waitForExpectations(timeout: 1)
    }
}
