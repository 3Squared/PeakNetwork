//
//  CertificatePinningTests.swift
//  Hubble
//
//  Created by Sam Oakley on 11/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import XCTest
@testable import Network

class CertificatePinningTests: XCTestCase {
    func testNoCertificate() {
        let expect = expectation(description: "")
        
        let certificatePinningSessionDelegate = CertificatePinningSessionDelegate()
        let urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: certificatePinningSessionDelegate,
                                    delegateQueue: nil)
        
        let networkOperation = URLResponseOperation(BlockRequestable {
            return URLRequest(url: URL(string: "https://google.com")!)
        }, session: urlSession)
        
        networkOperation.addResultBlock { result in
            do {
                try _ = result.resolve()
                XCTFail()
            } catch {
                expect.fulfill()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 5)
    }
    
    
    func testValidCertificate() {
        let expect = expectation(description: "")
        
        let certificatePinningSessionDelegate = CertificatePinningSessionDelegate()
        let urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: certificatePinningSessionDelegate,
                                    delegateQueue: nil)
        
        let networkOperation = URLResponseOperation(BlockRequestable {
            return URLRequest(url: URL(string: "https://github.com")!)
        }, session: urlSession)
        
        networkOperation.addResultBlock { result in
            do {
                try _ = result.resolve()
                expect.fulfill()
            } catch {
                XCTFail()
            }
        }
        
        networkOperation.enqueue()
        
        waitForExpectations(timeout: 5)
    }
    
}
