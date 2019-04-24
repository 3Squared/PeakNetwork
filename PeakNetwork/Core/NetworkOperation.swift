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
    public var unwrapped: MapOperation<Response<Body>, Body> {
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

/// The outcome of the requests. The object provided with the `Resource`
/// is associated with the the `Response` or `Error`.
public struct MultipleResourceOutcome<E, O> {
    public let successes: [(object: E, response: Response<O>)]
    public let failures: [(object: E, error: Error)]
}

/// Perform a series of network requests on an internal queue and aggregate the results.
open class MultipleResourceNetworkOperation<E, O>: ConcurrentOperation, ConsumesResult, ProducesResult {

    public let session: Session

    public var input: Result<[(object: E, resource: Resource<O>)], Error> = Result { throw ResultError.noResult }
    public var output: Result<MultipleResourceOutcome<E, O>, Error> = Result { throw ResultError.noResult }

    let internalQueue = OperationQueue()
    let dispatchQueue = DispatchQueue(label: "MultipleResourceNetworkOperation", attributes: .concurrent)

    /// Create a new `MultipleResourceNetworkOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - identifiableResources: A list of `IdentifiableResource` describing the web resources to fetch.
    ///     The object provided may be anything; it is not used, simply returned along with the `Response` or
    ///     `Error` associated with it. This way you may see which specific requests failed by using an ID or
    ///     a request body.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(identifiableResources: [(object: E, resource: Resource<O>)]? = nil, session: Session = URLSession.shared) {
        self.session = session
        if let identifiableResources = identifiableResources {
            input = .success(identifiableResources)
        }
        super.init()
    }

    open override func execute() {
        switch input {
        case .success(let resources):

            var successes: [(object: E, response: Response<O>)] = []
            var failures: [(object: E, error: Error)] = []

            let group = DispatchGroup()
            
            let operations: [NetworkOperation<O>] = resources.map { body, resource in
                group.enter()

                
                let operation = NetworkOperation(resource: resource, session: self.session)

                operation.addResultBlock { result in
                    self.dispatchQueue.async(flags: .barrier) {
                        switch result {
                        case .success(let response):
                            successes.append((body, response))
                        case .failure(let error):
                            failures.append((body, error))
                        }
                        group.leave()
                    }
                }
                
                return operation
            }

            self.internalQueue.addOperations(operations, waitUntilFinished: false)
            group.wait()
            self.output = .success(MultipleResourceOutcome(successes: successes, failures: failures))
            finish()
        case .failure(let error):
            output = .failure(error)
            finish()
        }
    }
}

public extension MultipleResourceNetworkOperation where E == Void {

    /// Create a new `MultipleResourceNetworkOperation`, parsing the response to a list of the given generic type.
    /// Use when you do not need to associate the `Response`/`Error` with a specific object.
    ///
    /// - Parameters:
    ///   - identifiableResources: A list of `Resource` describing the web resources to fetch.
    ///     The associated object is Void.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    convenience init(resources: [Resource<O>]? = nil, session: Session = URLSession.shared) {
        if let resources = resources {
            self.init(identifiableResources: resources.map { ((), $0) }, session: session)
        } else {
            self.init(identifiableResources: nil, session: session)
        }
    }
}
