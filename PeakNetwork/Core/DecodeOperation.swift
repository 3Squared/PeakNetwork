//
//  DecodingOperation.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 12/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#else
import AppKit
#endif
import PeakOperation
import PeakResult


/// Decode a network response using a `JSONDecoder`.
open class JSONDecodeOperation<D: Decodable>: MapOperation<NetworkResponse, D> {
    
    public let decoder: JSONDecoder

    /// Create a new `JSONDecodeOperation`.
    ///
    /// - Parameters:
    ///   - input: An optional input `NetworkResponse`.
    ///   - decoder: The `JSONDecoder` to use when decoding the response data (optional).
    public init(input: NetworkResponse? = nil,
                decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
        super.init(input: input)
    }
    
    override open func map(input: NetworkResponse) -> Result<D> {
        guard let data = input.data else {
            return .failure(SerializationError.noData)
        }
        
        return Result {
            return try decoder.decode(D.self, from: data)
        }
    }
}

/// Decode a network response using a `JSONDecoder`, keeping the `HTTPURLResponse` passed in.
open class JSONDecodeResponseOperation<D: Decodable>: MapOperation<NetworkResponse, (D, HTTPURLResponse)> {
    
    public let decoder: JSONDecoder
    
    /// Create a new `JSONDecodeResponseOperation`.
    ///
    /// - Parameters:
    ///   - input: An optional input `NetworkResponse`.
    ///   - decoder: The `JSONDecoder` to use when decoding the response data (optional).
    public init(input: NetworkResponse? = nil,
                decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
        super.init(input: input)
    }
    
    override open func map(input: NetworkResponse) -> Result<(D, HTTPURLResponse)> {
        guard let data = input.data else {
            return .failure(SerializationError.noData)
        }
        
        return Result {
            return (try decoder.decode(D.self, from: data), input.urlResponse)
        }
    }
}

/// Decode a network response into a platform-specific Image type
open class ImageDecodeOperation: MapOperation<NetworkResponse, PeakImage> {
    
    open override func map(input: NetworkResponse) -> Result<PeakImage> {
        if let data = input.data, let image = PeakImage(data: data) {
            return .success(image)
        } else {
            return .failure(ImageResponseOperationError.invalidData)
        }
    }

    public enum ImageResponseOperationError: Error {
        /// Could not initialize the image from the specified data.
        case invalidData
    }
}



/// Perform two operations, passing the result of the first to the second.
/// The input to this operation is used as the input to the first operation.
/// The output of the second operation is used as the output of this operation.
open class SequenceOperation<First, Second>: ConcurrentOperation, ProducesResult
    where
        First: ConcurrentOperation,
        Second: ConcurrentOperation,
        First: ProducesResult,
        First: ConsumesResult,
        Second: ProducesResult,
        Second: ConsumesResult,
        First.Output == Second.Input {
    
    public var input: Result<First.Input> = Result { throw ResultError.noResult }
    public var output: Result<Second.Output> = Result { throw ResultError.noResult }

    internal let queue = OperationQueue()
    
    internal let first: First
    internal let second: Second
    
    
    /// Create a new `SequenceOperation`.
    ///
    /// - Parameters:
    ///   - input: An optional input value.
    ///   - first: The first operation to perform.
    ///   - second: The second operation to perform, passed the output of `first`.
    public init(input: First.Input? = nil, do first: First, passResultTo second: Second) {
        self.first = first
        self.second = second
        if let input = input {
            first.input = .success(input)
        }
    }
    
    open override func execute() {
        guard !isCancelled else { return finish() }
        second.addResultBlock { [weak self] result in
            guard let strongSelf = self else { return }
            if !strongSelf.isCancelled {
                strongSelf.output = result
            }
            strongSelf.finish()
        }
        
        first
            .passesResult(to: second)
            .enqueue(on: queue)
    }

    
    open override func cancel() {
        queue.cancelAllOperations()
        super.cancel()
    }
}

/// `DecodableOperation` will attempt to parse the response into a `Decodable` type.
@available(*, deprecated, message: "Use a NetworkOperation chained with a DecodeOperation.")
open class DecodableOperation<D: Decodable>: SequenceOperation<NetworkOperation, JSONDecodeOperation<D>> {
    public init(requestable: Requestable?,
                decoder: JSONDecoder = JSONDecoder(),
                session: Session = URLSession.shared) {
        super.init(
            do: NetworkOperation(requestable: requestable, session: session),
            passResultTo: JSONDecodeOperation(decoder: decoder)
        )
    }
}

/// `DecodableResponseOperation` will attempt to parse the response into a `Decodable` type.
/// Alsoincludes the `HTTPURLResponse` in its `Result`.
@available(*, deprecated, message: "Use a NetworkOperation chained with a DecodeOperation.")
open class DecodableResponseOperation<D: Decodable>: SequenceOperation<NetworkOperation, JSONDecodeResponseOperation<D>> {
    public init(requestable: Requestable?,
                decoder: JSONDecoder = JSONDecoder(),
                session: Session = URLSession.shared) {
        super.init(
            do: NetworkOperation(requestable: requestable, session: session),
            passResultTo: JSONDecodeResponseOperation(decoder: decoder)
        )
    }
}


/// `DecodableFileOperation` will attempt to parse the contents of a file loaded from
/// the main bundle into a `Decodable` type.
open class DecodableFileOperation<Output: Decodable>: ConcurrentOperation, ProducesResult {

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
