//
//  CertificatePinningTests.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 11/11/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation
import XCTest

#if os(iOS)

@testable import PeakNetwork_iOS

#else

@testable import PeakNetwork_macOS

#endif

class CertificatePinningTests: XCTestCase {
    func testNoCertificate() {
        let expect = expectation(description: "")
        
        let certificatePinningSessionDelegate = CertificatePinningSessionDelegate()
        let urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: certificatePinningSessionDelegate,
                                    delegateQueue: nil)
        
        let networkOperation = URLResponseOperation(requestable: BlockRequestable {
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
        
        let networkOperation = URLResponseOperation(requestable: BlockRequestable {
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
