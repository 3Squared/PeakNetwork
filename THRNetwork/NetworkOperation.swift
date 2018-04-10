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
public class RequestOperation<D: Decodable>: NetworkOperation<(D, HTTPURLResponse)> {
    
    /// Create a new `RequestOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, decoder: JSONDecoder = JSONDecoder(), session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request, decoder: decoder) { (result: Result<(D, HTTPURLResponse)>) in
                self.output = result
                self.finish()
            }
        }
    }
}

public protocol HTTPHeaders {
    init(withHeaders headers: [AnyHashable: Any]) throws
}

/// A subclass of `NetworkOperation`.
/// `RequestWithHeadersOperation` will attempt to parse the response into a `Decodable` type, and the header fields into a `Headers` type.
public class RequestWithHeadersOperation<D: Decodable, H: HTTPHeaders>: NetworkOperation<(D, H, HTTPURLResponse)> {
    
    /// Create a new `RequestWithHeadersOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, decoder: JSONDecoder = JSONDecoder(), session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request, decoder: decoder) { (result: Result<(D, HTTPURLResponse)>) in
                self.output = Result {
                    let (decoded, response) = try result.resolve()
                    let headers = try H(withHeaders: response.allHeaderFields)
                    return (decoded, headers, response)
                }
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
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(Data?, HTTPURLResponse)>) in
                do {
                    let (_, response) = try result.resolve()
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
public class DataOperation: NetworkOperation<(Data, HTTPURLResponse)> {
    
    /// Create a new `DataOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(Data?, HTTPURLResponse)>) in
                do {
                    let (data, response) = try result.resolve()
                    if let d = data {
                        self.output = Result { return (d, response) }
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
public class ImageOperation: NetworkOperation<(UIImage, HTTPURLResponse)> {
    
    /// Create a new `ImageOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(Data?, HTTPURLResponse)>) in
                do {
                    let (data, response) = try result.resolve()
                    if let d = data, let image = UIImage(data: d) {
                        self.output = Result { return (image, response) }
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
    let error: Error?
    
    /// Create a new `MockRequestOperation`.
    /// To be used in tests and mocked builds with no network connectivity.
    /// The provided file is loaded and parsed in the same manner as `RequestOperation`.
    ///
    /// - Parameters:
    ///   - fileName: The name of a JSON file added to the main bundle.
    ///   - decoder: A `JSONDecoder` configured appropriately.
    ///   - error: An optional error that will be immediately thrown upon operation execution, for mocking network errors.
    public init(withFileName fileName: String, decoder: JSONDecoder = JSONDecoder(), error: Error? = nil) {
        self.fileName = fileName
        self.decoder = decoder
        self.error = error
    }
    
    override open func execute() {
        if let error = error {
            self.output = Result { throw error }
            self.finish()
        } else {
            DispatchQueue.main.async {
                let path = Bundle.allBundles.path(forResource: self.fileName, ofType: "json")!
                let jsonData = try! NSData(contentsOfFile: path) as Data
                let decodedData = try! self.decoder.decode(Output.self, from: jsonData)
                self.output = Result { decodedData }
                self.finish()
            }
        }
    }
}
