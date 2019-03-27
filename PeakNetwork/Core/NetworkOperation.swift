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

public typealias NetworkResponse = (data: Data?, urlResponse: HTTPURLResponse)

/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// Use when you want to perform network tasks in an operation queue.
// If `createTask` is overriden, ensure you call `finish` within your callback block.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation: RetryingOperation<NetworkResponse>, ConsumesResult {
    
    public var input: Result<Requestable, Error> = Result { throw ResultError.noResult }
    public let session: Session
    open var task: URLSessionTask?
    
    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(requestable: Requestable? = nil, session: Session = URLSession.shared) {
        self.session = session
        if let requestable = requestable {
            input = .success(requestable)
        }
        super.init()
    }
    
    /// Start the backing `URLSessionTask`.
    /// If retrying, the previous task will be cancelled first.
    open override func execute() {
        guard !isCancelled else { return finish() }
        switch (input) {
        case .success(let requestable):
            task?.cancel()
            task = createTask(with: requestable.request, using: session)
            task?.resume()
        case .failure(let error):
            output = .failure(error)
            finish()
        }
    }
    
    /// Cancel the backing `URLSessionTask`.
    override open func cancel() {
        super.cancel()
        task?.cancel()
    }
    
    
    /// Create a URLSessionTask to be performed in the Operation.
    ///
    /// - Parameters:
    ///   - request: A request passed from the provided Requestable
    ///   - session: The session on which to perform the task.
    /// - Returns: A URLSessionTask, or nil.
    open func createTask(with request: URLRequest, using session: Session) -> URLSessionTask? {
        return session.dataTask(with: request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            guard !strongSelf.isCancelled else { return strongSelf.finish() }

            if let error = error {
                strongSelf.output = Result { throw error }
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeValue.isSuccess {
                    strongSelf.output = .success((data, httpResponse))
                } else {
                    strongSelf.output = Result {
                        throw ServerError.error(code: httpResponse.statusCodeValue, data: data, response: httpResponse)
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
}

