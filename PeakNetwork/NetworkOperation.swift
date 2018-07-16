//
//  NetworkOperation.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import UIKit
import PeakOperations
import PeakResult


/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// Use when you want to perform network tasks in an operation queue.
// Override `createTask`, make a URLSessionTask, and ensure you call `finish` within your call back block.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation<T>: RetryingOperation<T> {
    internal var task: URLSessionTask?
    internal var session: Session

    public init(with session: Session) {
        self.session = session
        super.init()
    }
    
    /// Start the backing `URLSessionTask`.
    /// If retrying, the previous task will be cancelled first.
    open override func execute() {
        task?.cancel()
        task = createTask(in: session)
        task?.resume()
    }
    
    /// Cancel the backing `URLSessionTask`.
    override open func cancel() {
        super.cancel()
        task?.cancel()
    }
    
    open func createTask(in session: Session) -> URLSessionTask? {
        fatalError("Subclasses must implement `createTask`.")
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
/// `DecodableOperation` will attempt to parse the response into a `Decodable` type.
public class DecodableOperation<D: Decodable>: NetworkOperation<D> {
    
    private let requestable: Requestable
    private let decoder: JSONDecoder

    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, decoder: JSONDecoder = JSONDecoder(), session: Session = URLSession.shared) {
        self.requestable = requestable
        self.decoder = decoder
        super.init(with: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask {
        return session.dataTask(with: requestable.request, decoder: decoder) { [weak self] (result: Result<(D, HTTPURLResponse)>) in
            guard let strongSelf = self else { return }
            strongSelf.output = Result {
                let (decoded, _) = try result.resolve()
                return decoded
            }
            strongSelf.finish()
        }
    }
}

/// A subclass of `NetworkOperation`.
/// `DecodableResponseOperation` will attempt to parse the response into a `Decodable` type.
public class DecodableResponseOperation<D: Decodable>: NetworkOperation<(D, HTTPURLResponse)> {
    
    private let requestable: Requestable
    private let decoder: JSONDecoder

    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, decoder: JSONDecoder = JSONDecoder(), session: Session = URLSession.shared) {
        self.requestable = requestable
        self.decoder = decoder
        super.init(with: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask {
        return session.dataTask(with: requestable.request, decoder: decoder) { [weak self] (result: Result<(D, HTTPURLResponse)>) in
            guard let strongSelf = self else { return }
            strongSelf.output = result
            strongSelf.finish()
        }
    }
}

/// A subclass of `NetworkOperation` which will return the basic response.
public class URLResponseOperation: NetworkOperation<HTTPURLResponse> {
    
    private let requestable: Requestable

    /// Create a new `URLResponseOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: Session = URLSession.shared) {
        self.requestable = requestable
        super.init(with: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask {
        return session.dataTask(with: requestable.request)  { [weak self] (result: Result<(Data?, HTTPURLResponse)>) in
            guard let strongSelf = self else { return }
            do {
                let (_, response) = try result.resolve()
                strongSelf.output = Result { return response }
            } catch {
                strongSelf.output = Result { throw error }
            }
            strongSelf.finish()
        }
    }
}

/// A subclass of `NetworkOperation` which will return the response as `Data`.
public class DataResponseOperation: NetworkOperation<(Data, HTTPURLResponse)> {
    
    private let requestable: Requestable

    /// Create a new `DataResponseOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: Session = URLSession.shared) {
        self.requestable = requestable
        super.init(with: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask {
        return session.dataTask(with: requestable.request)  { [weak self] (result: Result<(Data?, HTTPURLResponse)>) in
            guard let strongSelf = self else { return }
            do {
                let (data, response) = try result.resolve()
                if let d = data {
                    strongSelf.output = Result { return (d, response) }
                } else {
                    strongSelf.output = Result { throw ResultError.noResult }
                }
            } catch {
                strongSelf.output = Result { throw error }
            }
            strongSelf.finish()
        }
    }
}

/// A subclass of `NetworkOperation` which will return the response parsed as a `UIImage`.
public class ImageResponseOperation: NetworkOperation<(UIImage, HTTPURLResponse)> {
    
    private let requestable: Requestable

    /// Create a new `ImageResponseOperation`.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable, session: Session = URLSession.shared) {
        self.requestable = requestable
        super.init(with: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask {
        return session.dataTask(with: requestable.request)  { [weak self] (result: Result<(Data?, HTTPURLResponse)>) in
            guard let strongSelf = self else { return }
            do {
                let (data, response) = try result.resolve()
                if let d = data, let image = UIImage(data: d) {
                    strongSelf.output = Result { return (image, response) }
                } else {
                    strongSelf.output = Result { throw ResultError.noResult }
                }
            } catch {
                strongSelf.output = Result { throw error }
            }
            strongSelf.finish()
        }
    }
}


/// `DecodableFileOperation` will attempt to parse the contents of a file loaded from
/// the main bundle into a `Decodable` type.
public class DecodableFileOperation<Output: Decodable>: ConcurrentOperation, ProducesResult {
    
    public var output: Result<Output> = Result { throw ResultError.noResult }

    let fileName: String
    let decoder: JSONDecoder
    
    /// Create a new `DecodableFileOperation`.
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
