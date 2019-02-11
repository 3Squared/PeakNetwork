//
//  NetworkOperation.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif
import PeakOperation
import PeakResult


/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// Use when you want to perform network tasks in an operation queue.
// Override `createTask`, make a URLSessionTask, and ensure you call `finish` within your call back block.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation<T>: RetryingOperation<T> {
    internal var task: URLSessionTask?
    internal var session: Session
    internal var requestable: Requestable!

    public init(_ requestable: Requestable? = nil, using session: Session) {
        self.session = session
        self.requestable = requestable
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
        return session.dataTask(with: requestable.request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                strongSelf.output = Result { throw error }
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeEnum.isSuccess {
                    if let data = data {
                        strongSelf.output = strongSelf.decode(data: data, response: httpResponse)
                    } else {
                        strongSelf.output = Result {
                            throw SerializationError.noData
                        }
                    }
                } else {
                    strongSelf.output = Result {
                        throw ServerError.error(code: httpResponse.statusCodeEnum, data: data, response: httpResponse)
                    }
                }
            } else {
                strongSelf.output = Result {
                    throw ServerError.unknownResponse
                }
            }
            
            strongSelf.finish()
        }
    }
    
    open func decode(data: Data, response: HTTPURLResponse) -> Result<T> {
        fatalError("Override me!")
    }
}

/// A subclass of `NetworkOperation`.
/// `DecodableOperation` will attempt to parse the response into a `Decodable` type.
public class DecodableOperation<D: Decodable>: NetworkOperation<D> {
    
    private let decoder: JSONDecoder

    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable?, decoder: JSONDecoder = JSONDecoder(), using session: Session = URLSession.shared) {
        self.decoder = decoder
        super.init(requestable, using: session)
    }
    
    public override func decode(data: Data, response: HTTPURLResponse) -> Result<D> {
        return Result {
            return try decoder.decode(D.self, from: data)
        }
    }
}

/// A subclass of `NetworkOperation`.
/// `DecodableResponseOperation` will attempt to parse the response into a `Decodable` type.
public class DecodableResponseOperation<D: Decodable>: NetworkOperation<(D, HTTPURLResponse)> {
    
    private let decoder: JSONDecoder

    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(_ requestable: Requestable?, decoder: JSONDecoder = JSONDecoder(), using session: Session = URLSession.shared) {
        self.decoder = decoder
        super.init(requestable, using: session)
    }
    
    public override func decode(data: Data, response: HTTPURLResponse) -> Result<(D, HTTPURLResponse)> {
        return Result {
            return (try decoder.decode(D.self, from: data), response)
        }
    }
}

/// A subclass of `NetworkOperation`.
/// `CustomNetworkInputOperation` will attempt to parse the response into a `Decodable` type.
/// You may override `requestableFrom` and `outputFrom` to add custom behaviour.
open class CustomNetworkInputOperation<D: Decodable, O, I>: NetworkOperation<O>, ConsumesResult {
    
    public var input: Result<I> = Result { throw ResultError.noResult }
    private let decoder: JSONDecoder
    
    /// Create a new `DynamicRequestableOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - session: The `JSONDecoder` to use when decoding the response data (optional).
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(decoder: JSONDecoder = JSONDecoder(), using session: Session = URLSession.shared) {
        self.decoder = decoder
        super.init(using: session)
    }
    
    open override func createTask(in session: Session) -> URLSessionTask? {
        if let requestable = requestableFrom(input) {
            self.requestable = requestable
            return super.createTask(in: session)
        } else {
            finish()
            return nil
        }
    }
    
    open override func decode(data: Data, response: HTTPURLResponse) -> Result<O> {
        return outputFrom(Result {
            return (try decoder.decode(D.self, from: data), response)
        })
    }
    
    /// Create a requestable to be performed, using the input to the operation.
    /// Must be overridden.
    ///
    /// - Parameter input: The input to this operation
    /// - Returns: A requestable to be performed
    open func requestableFrom(_ input: Result<I>) -> Requestable? {
        fatalError("Subclasses must implement `requestableFrom(:)`.")
    }
    
    /// Create the output result of the operation using the result of executing the requestable.
    /// Must be overridden.
    ///
    /// - Parameter result: The result of executing the requestable
    /// - Returns: The result to be used as output
    open func outputFrom(_ result: Result<(D, HTTPURLResponse)>) -> Result<O> {
        fatalError("Subclasses must implement `outputFrom(:)`.")
    }
}


/// A subclass of `NetworkOperation`.
/// `RequestableInputOperation` will take a `Requestable` input, call it, and attempt to parse the response into a `Decodable` type.
public class RequestableInputOperation<D: Decodable>: DecodableOperation<D>, ConsumesResult {
    
    public var input: Result<Requestable> = Result { throw ResultError.noResult }
    
    public init(decoder: JSONDecoder = JSONDecoder(), using session: Session = URLSession.shared) {
        super.init(nil, decoder: decoder, using: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask? {
        switch input {
        case .success(let requestable):
            self.requestable = requestable
            return super.createTask(in: session)
        case .failure(let error):
            output = Result { throw error }
            finish()
            return nil
        }
    }
}

/// A subclass of `NetworkOperation`.
/// `RequestableInputResponseOperation` will take a `Requestable` input, call it, and attempt to parse the response into a `Decodable` type.
public class RequestableInputResponseOperation<D: Decodable>: DecodableResponseOperation<D>, ConsumesResult {
    
    public var input: Result<Requestable> = Result { throw ResultError.noResult }
    
    public init(decoder: JSONDecoder = JSONDecoder(), using session: Session = URLSession.shared) {
        super.init(nil, decoder: decoder, using: session)
    }
    
    public override func createTask(in session: Session) -> URLSessionTask? {
        switch input {
        case .success(let requestable):
            self.requestable = requestable
            return super.createTask(in: session)
        case .failure(let error):
            output = Result { throw error }
            finish()
            return nil
        }
    }
}


/// A subclass of `NetworkOperation` which will return the basic response.
public class URLResponseOperation: NetworkOperation<HTTPURLResponse> {
    
    public override func decode(data: Data, response: HTTPURLResponse) -> Result<HTTPURLResponse> {
        return .success(response)
    }
}

/// A subclass of `NetworkOperation` which will return the response as `Data`.
public class DataResponseOperation: NetworkOperation<(Data, HTTPURLResponse)> {
    
    public override func decode(data: Data, response: HTTPURLResponse) -> Result<(Data, HTTPURLResponse)> {
        return .success((data, response))
    }
}

/// A subclass of `NetworkOperation` which will return the response parsed as a `UIImage`.
public class ImageResponseOperation: NetworkOperation<(PeakImage, HTTPURLResponse)> {
    
    public override func decode(data: Data, response: HTTPURLResponse) -> Result<(PeakImage, HTTPURLResponse)> {
        if let image = PeakImage(data: data) {
            return Result { return (image, response) }
        } else {
            return Result { throw ImageResponseOperationError.invalidData }
        }
    }
    
    public enum ImageResponseOperationError: Error {
        /// Could not initialize the image from the specified data.
        case invalidData
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
