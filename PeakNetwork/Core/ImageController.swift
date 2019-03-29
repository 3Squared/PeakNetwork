//
//  ImageController.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation

/// Allow remote images to be easilty set on UIImageViews.
/// Manages starting, cancellung, and mapping  of download operations.
public class ImageController {
    
    
    /// A convenience singleton used by the `UIKit` extension methods.
    /// If you need to customise their behavior, this variable can be overwritten
    /// with another your own instance of `ImageController`.
    public static var sharedInstance = ImageController()
    
    let internalQueue = OperationQueue()
    let urlToOperationTable = NSMapTable<NSURL, NetworkOperation<PeakImage>>.strongToWeakObjects()
    let objectToUrlTable = NSMapTable<NSObject, NSURL>.weakToStrongObjects()
    let urlsToObjectsTable = NSMapTable<NSURL, NSMutableSet>.weakToStrongObjects()

    let cache = NSCache<NSURL, PeakImage>()
    let session: Session
    
    
    /// Create a new `ImageController`.
    ///
    /// - Parameter session: The `URLSession` in which to perform the fetches (optional).
    public init(_ session: Session = URLSession.shared) {
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
    
    fileprivate func completeOperation(forObject object: NSObject) {
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
    public func getImage<T: NSObject>(_ url: URL, object: T, queue: OperationQueue? = nil, completion: @escaping (PeakImage?, T, Source) -> ()) {
        return getImage(Resource(url: url, headers: [:], method: .get), object: object, completion: completion)
    }
    
    /// Get an image available at the URL described by a Requestable. object is a unique key, such as an ImageView.
    public func getImage<T: NSObject>(_ resource: Resource<PeakImage>, object: T, queue: OperationQueue? = nil, completion: @escaping (PeakImage?, T, Source) -> ()) {
        
        // Cancel any in-flight operation for the same object
        cancelOperation(forObject: object)
        
        // Maybe we already have the image in the cache
        let url = resource.request.url! as NSURL
        if let image = cache.object(forKey: url) {
            completion(image, object, .cache)
            return
        }
        
        let imageOperation: NetworkOperation<PeakImage>
        var usingExisting = false
        if let existingOperation = urlToOperationTable.object(forKey: url) {
            imageOperation = existingOperation
            usingExisting = true
        } else {
            imageOperation = NetworkOperation(resource: resource, session: session)
        }
        
        // Create an operation to fetch the image data
        imageOperation.addResultBlock { result in
            if imageOperation.isCancelled {
                completion(nil, object, .network)
            } else {
                if let image = try? result.get().parsed {
                    self.cache.setObject(image, forKey: url)
                    completion(image, object, .network)
                } else {
                    completion(nil, object, .network)
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
}


/// An enum which describes the source of a loaded `UIImage`.
public enum Source {
    /// Loaded from the in-memory `NSCache`.
    case cache
    /// Loaded from the network, or possibly the on-disk cache.
    case network
}

#if os(iOS) || os(tvOS)

import UIKit

public extension PeakImageView {
    
    
    /// Set the image available at the `URL` as the `UIButton`'s image, for the given state.
    ///
    /// - Parameters:
    ///   - url: A URL to an image.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    func setImage(_ url: URL, queue: OperationQueue? = nil, animation: UIView.AnimationOptions? = nil, duration: TimeInterval = 0, completion: @escaping (Bool) -> () = { _ in }) {
        setImage(Resource(url: url, headers: [:], method: .get), queue: queue, animation: animation, duration: duration, completion: completion)
    }
    
    /// Set the image available at the `Resource` as the `UIButton`'s image, for the given state.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the location of an image.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    func setImage(_ resource: Resource<PeakImage>, queue: OperationQueue? = nil, animation: UIView.AnimationOptions? = nil, duration: TimeInterval = 0, completion: @escaping (Bool) -> () = { _ in }) {
        ImageController.sharedInstance.getImage(resource, object: self, queue: queue) { image, imageView, source in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if source == .network, let animationOptions = animation {
                    UIView.transition(with: imageView,
                                      duration: duration,
                                      options: animationOptions,
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
    
    /// Cancel any in-flight images requests for the `UIImageView`.
    func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}


public extension UIButton {
    
    /// Set the image available at the `URL` as the `UIButton`'s image, for the given state.
    /// You may set multiple images, one for each state, on a `UIButton` - only images for the same state will clash.
    ///
    /// - Parameters:
    ///   - url: A URL to an image.
    ///   - state: The `UIControlState` for which the image be displayed.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    func setImage(_ url: URL, queue: OperationQueue? = nil, for state: UIControl.State, animation: UIView.AnimationOptions? = nil, duration: TimeInterval = 0, completion: @escaping (Bool) -> () = { _ in }) {
        setImage(Resource(url: url, headers: [:], method: .get), for: state, queue: queue, animation: animation, duration: duration, completion: completion)
    }
    
    /// Set the image available at the `Resource` as the `UIButton`'s image, for the given state.
    /// You may set multiple images, one for each state, on a `UIButton` - only images for the same state will clash.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the location of an image.
    ///   - state: The `UIControlState` for which the image be displayed.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    func setImage(_ resource: Resource<PeakImage>, for state: UIControl.State, queue: OperationQueue? = nil, animation: UIView.AnimationOptions? = nil, duration: TimeInterval = 0, completion: @escaping (Bool) -> () = { _ in }) {
        // Cannot use self as the object, as you may want to request multiple images - one for each state
        let object: NSString = NSString.init(format: "%d%d", self.hash, state.rawValue)
        ImageController.sharedInstance.getImage(resource, object: object, queue: queue) { image, button, source in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if source == .network, let animationOptions = animation {
                    UIView.transition(with: self,
                                      duration: duration,
                                      options: animationOptions,
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
    
    
    /// Cancel any in-flight images requests for the `UIButton`.
    func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}

#endif
