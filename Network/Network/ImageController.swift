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
    
    static let sharedInstance = ImageController()
    
    let internalQueue = OperationQueue()
    let mapTable = NSMapTable<UIImageView, ImageOperation>.weakToWeakObjects()
    let cache = NSCache<NSURL, UIImage>()
    
    public init() {
        cache.totalCostLimit = 128 * 1024 * 1024;
    }
    
    
    /// Cancel a pending operation on the given imageview, if one exists.
    public func cancelOperation(forImageView imageView: UIImageView) {
        synchronized(mapTable) {
            if let previousOperation = mapTable.object(forKey: imageView) {
                previousOperation.cancel()
            }
            mapTable.removeObject(forKey: imageView)
        }
    }
    
    /// Set an image available at the URL described by a Requestable on a given imageView.
    public func setImage(_ requestable: Requestable, onImageView imageView: UIImageView, queue: OperationQueue? = nil, animated: Bool = false, completion: @escaping  (Bool) -> () = { _ in }) {
        
        // Cancel any in-flight operation for the same imageview
        cancelOperation(forImageView: imageView)
        
        // Maybe we already have the image in the cache
        let key = requestable.request.url! as NSURL
        if let image = cache.object(forKey: key) {
            setImage(image, toImageView: imageView, animated: animated, completion: completion)
            return
        }
        
        // Create an operation to fetch the image data
        let imageOperation = ImageOperation(requestable)
        imageOperation.addResultBlock { result in
            // Ensure that the operation completing is the most recent on for the imageView
            if let currentOperation = self.mapTable.object(forKey: imageView) {
                if currentOperation == imageOperation {
                    do {
                        let image = try result.resolve()
                        self.cache.setObject(image, forKey: key)
                        self.setImage(image, toImageView: imageView, animated: animated, completion: completion)
                    } catch {
                        completion(false)
                    }
                    
                    synchronized(self.mapTable) {
                        self.mapTable.removeObject(forKey: imageView)
                    }
                }
            }
        }
        
        synchronized(mapTable) {
            mapTable.setObject(imageOperation, forKey: imageView)
        }
        
        if let q = queue {
            imageOperation.enqueue(on: q)
        } else {
            imageOperation.enqueue(on: internalQueue)
        }
    }
    
    
    internal func setImage(_ image: UIImage, toImageView imageView: UIImageView, animated: Bool = false, completion: @escaping (Bool) -> () = { _ in }) {
        OperationQueue.main.addOperation {
            if animated {
                UIView.transition(with: imageView,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
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

public extension UIImageView {
    public func setImage(_ url: URL, queue: OperationQueue? = nil, animated: Bool = false, completion: @escaping (Bool) -> () = { _ in }) {
        ImageController.sharedInstance.setImage(URLRequestable(url), onImageView: self, queue: queue, animated: animated, completion: completion)
    }

    public func setImage(_ requestable: Requestable, queue: OperationQueue? = nil, animated: Bool = false, completion: @escaping (Bool) -> () = { _ in }) {
        ImageController.sharedInstance.setImage(requestable, onImageView: self, queue: queue, animated: animated, completion: completion)
    }
    
    public func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forImageView: self)
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
