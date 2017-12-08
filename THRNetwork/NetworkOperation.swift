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
/// `RequestOperation` will attempt to parse the response into a `Decodable` type.
public class RequestOperation<D: Decodable>: NetworkOperation<D> {
    
    /// Create a new `RequestOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, decoder: JSONDecoder = JSONDecoder(), session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request, decoder: decoder) { (result: Result<D>) in
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
                        self.output = Result { throw ResultError.noResult }
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
                        self.output = Result { throw ResultError.noResult }
                    }
                } catch {
                    self.output = Result { throw error }
                }
                
                self.finish()
            }
        }
    }
}

/// A subclass of `NetworkOperation`.
/// `MockRequestOperation` will attempt to parse the contents of a file loaded from
/// the main bundle into a `Decodable` type.
public class MockRequestOperation<Output: Decodable>: NetworkOperation<Output> {
    
    let fileName: String
    let decoder: JSONDecoder
    
    /// Create a new `MockRequestOperation`.
    /// To be used in tests and mocked builds with no network connectivity.
    /// The provided file is loaded and parsed in the same manner as `RequestOperation`.
    ///
    /// - Parameters:
    ///   - fileName: The name of a JSON file added to the main bundle.
    ///   - decoder: A `JSONDecoder` configured appropriately.
    public init(withFileName fileName: String, decoder: JSONDecoder = JSONDecoder()) {
        self.fileName = fileName
        self.decoder = decoder
    }
    
    override open func execute() {
        DispatchQueue.main.async {
            let path = Bundle.allBundles.path(forResource: self.fileName, ofType: "json")!
            let jsonData = try! NSData(contentsOfFile: path) as Data
            let decodedData = try! self.decoder.decode(Output.self, from: jsonData)
            self.output = Result { decodedData }
            self.finish()
        }
    }
}

