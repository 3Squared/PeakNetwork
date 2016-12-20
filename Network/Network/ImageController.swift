//
//  ImageController.swift
//  Hubble
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import UIKit

/// Allow remote images to be easilty set on UIImageViews.
/// Manages starting, cancellung, and mapping  of download operations.
public class ImageController {
    
    static var sharedInstance = ImageController()
    
    let internalQueue = OperationQueue()
    let mapTable = NSMapTable<NSObject, ImageOperation>.weakToWeakObjects()
    let cache = NSCache<NSURL, UIImage>()
    let session: URLSession

    public init(_ session: URLSession = URLSession.shared) {
        cache.totalCostLimit = 128 * 1024 * 1024;
        self.session = session
    }
    
    
    /// Cancel a pending operation on the given object, if one exists.
    public func cancelOperation(forObject object: NSObject) {
        synchronized(mapTable) {
            if let previousOperation = mapTable.object(forKey: object) {
                previousOperation.cancel()
            }
            mapTable.removeObject(forKey: object)
        }
    }
    
    
    /// Get an image available at the URL described by a Requestable. object is a unique key, such as an ImageView.
    public func getImage<T: NSObject>(_ requestable: Requestable, object: T, queue: OperationQueue? = nil, completion: @escaping (UIImage?, T) -> ()) {
        
        // Cancel any in-flight operation for the same object
        cancelOperation(forObject: object)
        
        // Maybe we already have the image in the cache
        let key = requestable.request.url! as NSURL
        if let image = cache.object(forKey: key) {
            completion(image, object)
            return
        }
        
        // Create an operation to fetch the image data
        let imageOperation = ImageOperation(requestable, session: session)
        imageOperation.addResultBlock { result in
            // Ensure that the operation completing is the most recent
            if let currentOperation = self.mapTable.object(forKey: object) {
                if currentOperation == imageOperation {
                    do {
                        let image = try result.resolve()
                        self.cache.setObject(image, forKey: key)
                        completion(image, object)
                    } catch {
                        completion(nil, object)
                    }
                    
                    synchronized(self.mapTable) {
                        self.mapTable.removeObject(forKey: object)
                    }
                }
            }
        }
        
        synchronized(mapTable) {
            mapTable.setObject(imageOperation, forKey: object)
        }
        
        if let q = queue {
            imageOperation.enqueue(on: q)
        } else {
            imageOperation.enqueue(on: internalQueue)
        }
    }
}

public struct AnimationOptions
{
    let duration: TimeInterval
    let options: UIViewAnimationOptions
    
    init(duration: TimeInterval, options: UIViewAnimationOptions) {
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
                if let animationOptions = animation {
                    UIView.transition(with: imageView,
                                      duration: animationOptions.duration,
                                      options: animationOptions.options,
                                      animations: {
                                        imageView.image = image
                    }, completion: completion)
                } else {
                    imageView.image = image
                    completion(true)
                }
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
        ImageController.sharedInstance.getImage(requestable, object: self, queue: queue) { image, button in
            OperationQueue.main.addOperation {
                if let animationOptions = animation {
                    UIView.transition(with: button,
                                      duration: animationOptions.duration,
                                      options: animationOptions.options,
                                      animations: {
                                        button.setImage(image, for: state)
                    }, completion: completion)
                } else {
                    button.setImage(image, for: state)
                    completion(true)
                }
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
