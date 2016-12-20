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
    
    func testSharedInstance() {
        XCTAssert(ImageController.sharedInstance === ImageController.sharedInstance)
    }
    
    func testSetSharedInstance() {
        let original = ImageController.sharedInstance
        let new = ImageController(URLSession())
        
        ImageController.sharedInstance = new
        XCTAssertFalse(ImageController.sharedInstance === original)
        XCTAssert(ImageController.sharedInstance === new)
    }
    
    func testGetImage() {
        let expect = expectation(description: "")
        
        let context: NSString = "Hello"

        ImageController.sharedInstance.getImage(URLRequestable(URL(string: "https://placehold.it/350x350")!), object: context) { image, thing in
            XCTAssertEqual(context, thing)
            XCTAssertNotNil(image)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }

    
    func testSetImage() {
        let expect = expectation(description: "")
        let imageView = UIImageView(frame: CGRect.zero)
        
        XCTAssertNil(imageView.image)
        imageView.setImage(URL(string: "https://placehold.it/350x350")!) { finished in
            XCTAssertNotNil(imageView.image)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testSetImageOnButton() {
        let expect = expectation(description: "")
        let button = UIButton(frame: CGRect.zero)
        
        XCTAssertNil(button.image(for: .normal))
        button.setImage(URL(string: "https://placehold.it/350x350")!, for: .normal) { finished in
            XCTAssertNotNil(button.image(for: .normal))
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
        
        waitForExpectations(timeout: 2)
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
