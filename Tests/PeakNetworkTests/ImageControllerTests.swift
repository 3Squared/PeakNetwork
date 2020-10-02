//
//  ImageControllerTests.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import XCTest
@testable import PeakNetwork

class ImageControllerTests: XCTestCase {
    
    let api = MyAPI()

    override func setUp() {
        super.setUp()
        
        let bundle = Bundle.module
        let data300 = try! Data(contentsOf: bundle.url(forResource: "300", withExtension: "png")!)
        let data600 = try! Data(contentsOf: bundle.url(forResource: "600", withExtension: "png")!)

        let session = MockSession { session in
            session.queue(response: MockResponse(data: data300, statusCode: .ok, sticky: true) { request in
                return request.url?.path == "/300"
            })
            session.queue(response: MockResponse(data: data600, statusCode: .ok, sticky: true) { request in
                return request.url?.path == "/600"
            })
        }
        
        let new = ImageController(session)
        ImageController.sharedInstance = new
    }

    
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

        ImageController.sharedInstance.getImage(URL(string: "https://placehold.it/300")!, object: context) { image, thing, source in
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
        imageView.setImage(URL(string: "https://placehold.it/300")!) { success in
            XCTAssertNotNil(imageView.image)
            XCTAssertTrue(success)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testSetImageWithAnimation() {
        let expect = expectation(description: "")
        let imageView = UIImageView(frame: CGRect.zero)
        XCTAssertNil(imageView.image)
        imageView.setImage(URL(string: "https://placehold.it/300")!, animation: [.transitionCrossDissolve], duration: 0.1) { success in
            XCTAssertNotNil(imageView.image)
            XCTAssertTrue(success)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testSetImageOnButton() {
        let expect = expectation(description: "")
        let button = UIButton(frame: CGRect.zero)
        
        XCTAssertNil(button.image(for: .normal))
        button.setImage(URL(string: "https://placehold.it/300")!, for: .normal) { success in
            XCTAssertNotNil(button.image(for: .normal))
            XCTAssertTrue(success)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testCancellingImage() {
        let queue = OperationQueue()
        
        let imageView = UIImageView(frame: CGRect.zero)
        
        imageView.setImage(URL(string: "https://placehold.it/300")!, queue: queue) { success in
            XCTAssertNil(imageView.image)
            XCTAssertFalse(success)
        }
        XCTAssertEqual(queue.operations.count, 1)
        imageView.cancelImage()
        
        expectation(for: NSPredicate(block: { _, _ -> Bool in
            print("operations == \(queue.operations.count)")
            return queue.operations.count == 0
        }), evaluatedWith: queue, handler: nil)
        
        waitForExpectations(timeout: 2)
    }
    
    func testSecondRequestCancelsFirst() {
        let expect = expectation(description: "")
        let queue = OperationQueue()
        
        let imageView = UIImageView(frame: CGRect.zero)
        
        imageView.setImage(URL(string: "https://placehold.it/300")!, queue: queue) { success in
            XCTAssertFalse(success)
        }
        XCTAssertEqual(queue.operations.count, 1)
        
        imageView.setImage(URL(string: "https://placehold.it/300")!, queue: queue) { success in
            XCTAssertTrue(success)
            expect.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
    
    func testSecondRequestIsMerged() {
        let expect1 = expectation(description: "image1")
        let expect2 = expectation(description: "image2")

        let queue = OperationQueue()
        
        let imageView1 = UIImageView(frame: CGRect.zero)
        imageView1.accessibilityHint = "imageView1"
        let imageView2 = UIImageView(frame: CGRect.zero)
        imageView2.accessibilityHint = "imageView2"

        
        var image1: UIImage?
        var image2: UIImage?

        ImageController.sharedInstance.getImage(URL(string: "https://placehold.it/300")!, object: imageView1, queue: queue) { image, view, source in
            image1 = image
            expect1.fulfill()
        }
        
        ImageController.sharedInstance.getImage(URL(string: "https://placehold.it/300")!, object: imageView2, queue: queue) { image, view, source in
            image2 = image
            expect2.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        
        XCTAssertNotNil(image1)
        XCTAssertEqual(image1, image2)
    }

    func testSecondRequestIsNotCancelledIfFirstIs() {
        let expect = expectation(description: "")
        
        let queue = OperationQueue()
        
        let imageView1 = UIImageView(frame: CGRect.zero)
        imageView1.accessibilityHint = "imageView1"
        let imageView2 = UIImageView(frame: CGRect.zero)
        imageView2.accessibilityHint = "imageView2"
        
        
        ImageController.sharedInstance.getImage(URL(string: "https://placehold.it/300")!, object: imageView1, queue: queue) { image, view, source in
            DispatchQueue.main.async {
                XCTAssertNil(imageView1.image)
            }
        }
        
        ImageController.sharedInstance.getImage(URL(string: "https://placehold.it/300")!, object: imageView2, queue: queue) { image, view, source in
            DispatchQueue.main.async {
                XCTAssertNotNil(image)
            }
            expect.fulfill()
        }
        
        ImageController.sharedInstance.cancelOperation(forObject: imageView1)
    
        waitForExpectations(timeout: 5)
    }

    
}
