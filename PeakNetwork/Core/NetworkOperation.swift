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

public struct Response<Body> {
    public let data: Data?
    public let urlResponse: HTTPURLResponse
    public let parsed: Body
    
    public init(data: Data?, urlResponse: HTTPURLResponse, parsed: Body) {
        self.data = data
        self.urlResponse = urlResponse
        self.parsed = parsed
    }
}

/// Use when you want to perform network tasks in an operation queue.
/// The given `Resource`'s `parse` method will be used to decode the response data.
///
/// If `createTask` is overriden, ensure you call `finish` within your callback block.
/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation<Body>: RetryingOperation<Response<Body>>, ConsumesResult {
    
    public var input: Result<Resource<Body>, Error> = Result { throw ResultError.noResult }
    public let session: Session
    open var task: URLSessionTask?
    
    internal var downloadProgress = Progress(totalUnitCount: 1)

    /// Create a new `NetworkOperation`, parsing the response into the `Resource`'s type.
    ///
    /// - Parameters:
    ///   - requestable: A `Resource` describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(resource: Resource<Body>? = nil, session: Session = URLSession.shared) {
        self.session = session
        if let resource = resource {
            input = .success(resource)
        }
        super.init()
    }
    
    /// Start the backing `URLSessionTask`.
    /// If retrying, the previous task will be cancelled first.
    open override func execute() {
        guard !isCancelled else { return finish() }
        switch (input) {
        case .success(let resource):
            task?.cancel()
            task = createTask(with: resource, using: session)
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
    open func createTask(with resource: Resource<Body>, using session: Session) -> URLSessionTask? {
        let task = session.dataTask(with: resource.request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            guard !strongSelf.isCancelled else { return strongSelf.finish() }

            if let error = error {
                strongSelf.output = Result { throw error }
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeValue.isSuccess {
                    strongSelf.output = Result {
                        Response(data: data, urlResponse: httpResponse, parsed: try resource.parse(data))
                    }
                } else {
                    strongSelf.output = .failure(ServerError.error(code: httpResponse.statusCodeValue, data: data, response: httpResponse))
                }
            } else {
                strongSelf.output = .failure(ServerError.unknownResponse)
            }
            strongSelf.finish()
        }
        
        if #available(iOS 11.0, *) {
            progress.addChild(task.progress, withPendingUnitCount: progress.totalUnitCount)
        }
        
        return task
    }
}

extension NetworkOperation {
    /// Unwrap the Response and return a result containing only the
    /// parsed data, discarding the network response information.
    public func unwrapBodyOperation() -> MapOperation<Response<Body>, Body> {
        return passesResult(to: BlockMapOperation<Response<Body>, Body> { input in
            switch (input) {
            case .success(let response):
                return .success(response.parsed)
            case .failure(let error):
                return .failure(error)
            }
        })
    }
}

extension NetworkOperation  {
    /// Use to chain a NetworkOperation into something that only wants the response body.
    ///
    /// - Parameter operation: The operation to pass the parsed response body to.
    /// - Returns: The dependant operation, with the dependancy added.
    @discardableResult
    public func passesBody<Consumer>(to operation: Consumer) -> Consumer where Consumer: Operation, Consumer: ConsumesResult, Consumer.Input == Body {
        operation.addDependency(self)
        addWillFinishBlock { [weak self, unowned operation] in
            guard let strongSelf = self else { return }
            if !strongSelf.isCancelled {
                switch (strongSelf.output) {
                case .success(let response):
                    operation.input = .success(response.parsed)
                case .failure(let error):
                    operation.input = .failure(error)
                }
            }
        }
        return operation
    }
}
