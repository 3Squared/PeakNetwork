//
//  ImageController.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 17/11/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import UIKit
import THRResult

/// Allow remote images to be easilty set on UIImageViews.
/// Manages starting, cancellung, and mapping  of download operations.
public class ImageController {
    
    
    /// A convenience singleton used by the `UIKit` extension methods.
    /// If you need to customise their behavior, this variable can be overwritten
    /// with another your own instance of `ImageController`.
    public static var sharedInstance = ImageController()
    
    let internalQueue = OperationQueue()
    let urlToOperationTable = NSMapTable<NSURL, ImageResponseOperation>.strongToWeakObjects()
    let objectToUrlTable = NSMapTable<NSObject, NSURL>.weakToStrongObjects()
    let urlsToObjectsTable = NSMapTable<NSURL, NSMutableSet>.weakToStrongObjects()

    let cache = NSCache<NSURL, UIImage>()
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
    public func getImage<T: NSObject>(_ requestable: Requestable, object: T, queue: OperationQueue? = nil, completion: @escaping (UIImage?, T, Source) -> ()) {
        
        // Cancel any in-flight operation for the same object
        cancelOperation(forObject: object)
        
        // Maybe we already have the image in the cache
        let url = requestable.request.url! as NSURL
        if let image = cache.object(forKey: url) {
            completion(image, object, .cache)
            return
        }
        
        let imageOperation: ImageResponseOperation
        var usingExisting = false
        if let existingOperation = urlToOperationTable.object(forKey: url) {
            imageOperation = existingOperation
            usingExisting = true
        } else {
            imageOperation = ImageResponseOperation(requestable, session: session)
        }
        
        // Create an operation to fetch the image data
        imageOperation.addResultBlock { result in
            if imageOperation.isCancelled {
                completion(nil, object, .network)
            } else {
                do {
                    let (image, _) = try result.resolve()
                    self.cache.setObject(image, forKey: url)
                    completion(image, object, .network)
                } catch {
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


/// Describes the AnimationOptions to be used when setting an image on a view.
public struct AnimationOptions {
    
    /// The duration of the animation.
    public let duration: TimeInterval
    /// The animation options.
    public let options: UIViewAnimationOptions
    
    
    /// Create a new `AnimationOptions`.
    ///
    /// - Parameters:
    ///   - duration: The duration of the animation.
    ///   - options: The animation options.
    public init(duration: TimeInterval, options: UIViewAnimationOptions) {
        self.duration = duration
        self.options = options
    }
}


public extension UIImageView {
    
    /// Set the image available at the given URL as the `UIImageView`'s image.
    ///
    /// - Parameters:
    ///   - url: The URL of an image.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    public func setImage(_ url: URL, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        self.setImage(URLRequestable(url), queue: queue, animation: animation, completion: completion)
    }
    
    /// Set the image available at the resource described by the given `Requestable` as the `UIButton`'s image, for the given state.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the location of an image.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    public func setImage(_ requestable: Requestable, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        ImageController.sharedInstance.getImage(requestable, object: self, queue: queue) { image, imageView, source in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if source == .network, let animationOptions = animation {
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
    
    /// Cancel any in-flight images requests for the `UIImageView`.
    public func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}


public extension UIButton {

    /// Set the image available at the given URL as the `UIButton`'s image, for the given state.
    /// You may set multiple images, one for each state, on a `UIButton` - only images for the same state will clash.
    ///
    /// - Parameters:
    ///   - url: The URL of an image.
    ///   - state: The `UIControlState` for which the image be displayed.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    public func setImage(_ url: URL, for state: UIControlState, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        self.setImage(URLRequestable(url), for: state, queue: queue, animation: animation, completion: completion)
    }
    
    
    /// Set the image available at the resource described by the given `Requestable` as the `UIButton`'s image, for the given state.
    /// You may set multiple images, one for each state, on a `UIButton` - only images for the same state will clash.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the location of an image.
    ///   - state: The `UIControlState` for which the image be displayed.
    ///   - queue: The `OperationQueue` on which to run the `ImageOperation` (optional).
    ///   - animation: The animation options (optional).
    ///   - completion: A completion block indicating success or failure.
    public func setImage(_ requestable: Requestable, for state: UIControlState, queue: OperationQueue? = nil, animation: AnimationOptions? = nil, completion: @escaping (Bool) -> () = { _ in }) {
        // Cannot use self as the object, as you may want to request multiple images - one for each state
        let object: NSString = NSString.init(format: "%d%d", self.hash, state.rawValue)
        ImageController.sharedInstance.getImage(requestable, object: object, queue: queue) { image, button, source in
            OperationQueue.main.addOperation {
                if image == nil {
                    completion(false)
                    return
                }
                if source == .network, let animationOptions = animation {
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
    
    
    /// Cancel any in-flight images requests for the `UIButton`.
    public func cancelImage() {
        ImageController.sharedInstance.cancelOperation(forObject: self)
    }
}
