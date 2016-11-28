//
//  ImageControllerTests.swift
//  Hubble
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import Network

class ImageControllerTests: XCTestCase {
    
    func testSetImage() {
        let expect = expectation(description: "")
        let imageView = UIImageView(frame: CGRect.zero)
        
        imageView.setImage(URL(string: "https://placehold.it/350x350")!) { finished in
            XCTAssertNotNil(imageView.image)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func testCancellingImage() {
        let queue = OperationQueue()
        
        let imageView = UIImageView(frame: CGRect.zero)
        
        imageView.setImage(BlockRequestable {
            return URLRequest(url: URL(string: "https://placehold.it/350x350")!)
        }, queue: queue) { finished in
            XCTFail()
        }
        XCTAssertEqual(queue.operations.count, 1)
        imageView.cancelImage()
        
        expectation(for: NSPredicate(block: { _, _ -> Bool in
            return queue.operations.count == 0
        }), evaluatedWith: queue, handler: nil)
        
        waitForExpectations(timeout: 1)
    }
    
    func testSecondRequestCancelsFirst() {
        let expect = expectation(description: "")
        let queue = OperationQueue()
        
        let imageView = UIImageView(frame: CGRect.zero)
        
        imageView.setImage(BlockRequestable {
            return URLRequest(url: URL(string: "https://placehold.it/350x350")!)
        }, queue: queue) { finished in
            XCTFail()
        }
        XCTAssertEqual(queue.operations.count, 1)
        
        imageView.setImage(BlockRequestable {
            return URLRequest(url: URL(string: "https://placehold.it/500x500")!)
        }, queue: queue) { finished in
            expect.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
    
}
