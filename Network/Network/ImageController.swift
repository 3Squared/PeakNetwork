//
//  ImageController.swift
//  Hubble
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import UIKit
import THRResult

/// Allow remote images to be easilty set on UIImageViews.
/// Manages starting, cancellung, and mapping  of download operations.
public class ImageController {
    
    public static var sharedInstance = ImageController()
    
    let internalQueue = OperationQueue()
    let urlToOperationTable = NSMapTable<NSURL, ImageOperation>.strongToWeakObjects()
    let objectToUrlTable = NSMapTable<NSObject, NSURL>.weakToStrongObjects()
    let urlsToObjectsTable = NSMapTable<NSURL, NSMutableSet>.weakToStrongObjects()

    let cache = NSCache<NSURL, UIImage>()
    let session: URLSession
    
    public init(_ session: URLSession = URLSession.shared) {
        cache.totalCostLimit = 128 * 1024 * 1024;
        self.session = session
    }
    
    
    /// Cancel a pending operation on the given object, if one exists.
    public func cancelOperation(forObject object: NSObject) {
        if let url = objectToUrlTable.object(forKey: object) {
            let objects = urlsToObjectsTable.object(forKey: url)
            objects?.remove(object)
            if objects?.count == 0 {
                urlToOperationTable.object(forKey: url)?.cancel()
                urlToOperationTable.removeObject(forKey: url)
            }
        }
        objectToUrlTable.removeObject(forKey: object)
    }
    
    public func completeOperation(forObject object: NSObject) {
        if let url = objectToUrlTable.object(forKey: object) {
            let objects = urlsToObjectsTable.object(forKey: url)
            objects?.remove(object)
            if objects?.count == 0 {
                urlToOperationTable.removeObject(forKey: url)
            }
        }
        objectToUrlTable.removeObject(forKey: object)
    }
    
    
    /// Get an image available at the URL described by a Requestable. object is a unique key, such as an ImageView.
    public func getImage<T: NSObject>(_ requestable: Requestable, object: T, queue: OperationQueue? = nil, completion: @escaping (UIImage?, T) -> ()) {
        
        // Cancel any in-flight operation for the same object
        cancelOperation(forObject: object)
        
        // Maybe we already have the image in the cache
        let url = requestable.request.url! as NSURL
        if let image = cache.object(forKey: url) {
            completion(image, object)
            return
        }
        
        let imageOperation: ImageOperation
        var usingExisting = false
        if let existingOperation = urlToOperationTable.object(forKey: url) {
            imageOperation = existingOperation
            usingExisting = true
        } else {
            imageOperation = ImageOperation(requestable, session: session)
        }
        
        // Create an operation to fetch the image data
        imageOperation.addResultBlock { result in
            if imageOperation.isCancelled {
                completion(nil, object)
            } else {
                do {
                    let image = try result.resolve()
                    self.cache.setObject(image, forKey: url)
                    completion(image, object)
                } catch {
                    completion(nil, object)
                }
            }
            
            self.completeOperation(forObject: object)
        }
        
        urlToOperationTable.setObject(imageOperation, forKey: url)
        objectToUrlTable.setObject(url, forKey: object)
        
        if let objects =  urlsToObjectsTable.object(forKey: url) {
            objects.add(object)
        } else {
            urlsToObjectsTable.setObject(NSMutableSet(), forKey: url)
            urlsToObjectsTable.object(forKey: url)?.add(object)
        }
        
        if !usingExisting {
            if let q = queue {
                imageOperation.enqueue(on: q)
            } else {
                imageOperation.enqueue(on: internalQueue)
            }
        }
    
    }
    
    private func resultBlock(result: Result<UIImage>) {
        
    }
}

public struct AnimationOptions
{
    public let duration: TimeInterval
    public let options: UIViewAnimationOptions
    
    public init(duration: TimeInterval, options: UIViewAnimationOptions) {
        self.duration = duration
        self.options = options
    }
}

public extension UIImageView {
    public func setImage(_ url: URL, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        self.setImage(URLRequestable(url), queue: queue, animation: animation, completion: completion)
    }
    
    public func setImage(_ requestable: Requestable, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        ImageController.sharedInstance.getImage(requestable, object: self, queue: queue) { image, imageView in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if let animationOptions = animation {
                    UIView.transition(with: imageView,
                                      duration: animationOptions.duration,
                                      options: animationOptions.options,
                                      animations: {
                                        imageView.image = image
                    }, completion: nil)
                } else {
                    imageView.image = image
                }
                completion(true)
            }
        }
    }
    
    public func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}

public extension UIButton {
    public func setImage(_ url: URL, for state: UIControlState, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        self.setImage(URLRequestable(url), for: state, queue: queue, animation: animation, completion: completion)
    }
    
    public func setImage(_ requestable: Requestable, for state: UIControlState, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        // Cannot use self as the object, as you may want to request multiple images - one for each state
        let object: NSString = NSString.init(format: "%d%d", self.hash, state.rawValue)
        ImageController.sharedInstance.getImage(requestable, object: object, queue: queue) { image, button in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if let animationOptions = animation {
                    UIView.transition(with: self,
                                      duration: animationOptions.duration,
                                      options: animationOptions.options,
                                      animations: {
                                        self.setImage(image, for: state)
                    }, completion: nil)
                } else {
                    self.setImage(image, for: state)
                }
                completion(true)
            }
        }
    }
    
    public func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}

/// Emulate the functionality of ObjC's @synchronized
func synchronized(_ lock: AnyObject, block:() throws -> Void) rethrows {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    try block()
}
