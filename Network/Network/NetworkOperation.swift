//
//  GetRepositoryProcedure.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import UIKit
import THROperations
import THRResult


/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// Use when you want to perform network tasks in an operation queue.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation<T>: RetryingOperation<T> {
    internal var task: URLSessionTask?
    internal var taskMaker: (() -> (URLSessionTask))!
    
    
    /// Start the backing `URLSessionTask`.
    /// If retrying, the previous task will be cancelled first.
    open override func execute() {
        task?.cancel()
        task = taskMaker()
        task?.resume()
    }
    
    
    /// Cancel the backing `URLSessionTask`.
    override open func cancel() {
        super.cancel()
        task?.cancel()
    }
}


/// Implement this protocol to signify that the object can be converted into a `URLRequest`.
/// A common pattern is to implement this on an extension to an enum, describing your API endpoints.
public protocol Requestable {
    
    /// Return a `URLRequest` configured to represent the object.
    var request: URLRequest { get }
}

/// Creates a `Requestable` using a given `URL`.
public class URLRequestable: Requestable {
    
    /// :nodoc:
    public var request: URLRequest

    /// Create a new `URLRequestable` with a given `URL`.
    ///
    /// - Parameter url: A `URL`.
    public init(_  url: URL) {
        request = URLRequest(url: url)
    }
}

/// Creates a `Requestable` using a given block.
public class BlockRequestable: Requestable {
    
    /// :nodoc:
    public var request: URLRequest
    
    /// Create a new `BlockRequestable` with a given block.
    ///
    /// - Parameter block: A block returning a `URLRequest`.
    public init(_  block:  () -> URLRequest) {
        request = block()
    }
}

/// A subclass of `NetworkOperation`.
/// `RequestOperation` will attempt to parse the response into a list of type `J`, 
/// using the initialiser definied in the `JSONConvertible` protocol.
///
/// The `Result` of the operation will always be a list, but the parser will handle both
/// `JSONArray`s and single `JSONObject`s returned by the request. To use a single object,
/// simply get the only object in the `Result`'s array.
public class RequestOperation<J:JSONConvertible>: NetworkOperation<[J]> {
    
    /// Create a new `RequestOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request) { (result: Result<[J]>) in
                self.output = result
                self.finish()
            }
        }
    }
}

/// A subclass of `NetworkOperation` which will return the basic response.
public class URLResponseOperation: NetworkOperation<HTTPURLResponse> {
    
    /// Create a new `URLResponseOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (response, _) = try result.resolve()
                    self.output = Result { return response }
                } catch {
                    self.output = Result { throw error }
                }
                self.finish()
            }
        }
    }
}

/// A subclass of `NetworkOperation` which will return the response as `Data`.
public class DataOperation: NetworkOperation<Data> {
    
    /// Create a new `DataOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (_, data) = try result.resolve()
                    if let d = data {
                        self.output = Result { return d }
                    } else {
                        self.output = Result { throw OperationError.noResult }
                    }
                } catch {
                    self.output = Result { throw error }
                }
                self.finish()
            }
        }
    }
}

/// A subclass of `NetworkOperation` which will return the response parsed as a `UIImage`.
public class ImageOperation: NetworkOperation<UIImage> {
    
    /// Create a new `ImageOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (_, data) = try result.resolve()
                    if let d = data, let image = UIImage(data: d) {
                        self.output = Result { return image }
                    } else {
                        self.output = Result { throw OperationError.noResult }
                    }
                } catch {
                    self.output = Result { throw error }
                }
                
                self.finish()
            }
        }
    }
}

