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

public struct Response<O> {
    let data: Data?
    let urlResponse: HTTPURLResponse
    let parsed: O?
}

/// A subclass of `RetryingOperation` which wraps a `URLSessionTask`.
/// Use when you want to perform network tasks in an operation queue.
/// If `createTask` is overriden, ensure you call `finish` within your callback block.
/// If a `RetryStrategy` is provided, this can be re-run if the network task fails (not 200).
open class NetworkOperation<O>: RetryingOperation<Response<O>>, ConsumesResult {
    
    public var input: Result<Resource<O>> = Result { throw ResultError.noResult }
    public let session: Session
    open var task: URLSessionTask?
    
    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(resource: Resource<O>? = nil, session: Session = URLSession.shared) {
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
    open func createTask(with resource: Resource<O>, using session: Session) -> URLSessionTask? {
        return session.dataTask(with: resource.request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            guard !strongSelf.isCancelled else { return strongSelf.finish() }

            if let error = error {
                strongSelf.output = Result { throw error }
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeEnum.isSuccess {
                    strongSelf.output = .success(Response(data: data, urlResponse: httpResponse, parsed: resource.parse(data)))
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
}


/// Perform a series of network requests on an internal queue and aggregate the results.
open class MultipleResourceNetworkOperation<O>: ConcurrentOperation, ConsumesResult, ProducesResult {

    /// The outcome of the requests.
    public struct Outcome {
        let successes: [Response<O>]
        let failures: [Error]
    }

    public let session: Session

    public var input: Result<[Resource<O>]> = Result { throw ResultError.noResult }
    public var output: Result<Outcome> = Result { throw ResultError.noResult }

    let internalQueue = OperationQueue()
    let dispatchQueue = DispatchQueue(label: "GroupRequestNetworkOperation", attributes: .concurrent)

    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
    ///
    /// - Parameters:
    ///   - requestable: A requestable describing the web resource to fetch.
    ///   - session: The `URLSession` in which to perform the fetch (optional).
    public init(resources: [Resource<O>]? = nil, session: Session = URLSession.shared) {
        self.session = session
        if let resources = resources {
            input = .success(resources)
        }
        super.init()
    }

    open override func execute() {
        switch input {
        case .success(let resources):

            var successes: [Response<O>] = []
            var failures: [Error] = []

            let group = DispatchGroup()
            
            let operations: [NetworkOperation<O>] = resources.map { resource in
                group.enter()

                let operation = NetworkOperation(resource: resource, session: self.session)

                operation.addResultBlock { result in
                    self.dispatchQueue.async(flags: .barrier) {
                        switch result {
                        case .success(let response):
                            successes.append(response)
                        case .failure(let error):
                            failures.append(error)
                        }
                        group.leave()
                    }
                }
                
                return operation
            }

            self.internalQueue.addOperations(operations, waitUntilFinished: false)
            group.wait()
            self.output = .success(Outcome(successes: successes, failures: failures))
            finish()
        case .failure(let error):
            output = .failure(error)
            finish()
        }
    }
}

///// Perform a series of network requests on an internal queue and aggregate the results.
//open class MultipleBodyRequestNetworkOperation<E: Encodable>: ConcurrentOperation, ConsumesResult, ProducesResult {
//
//    /// The outcome of the requests.
//    public struct Outcome {
//
//        /// Successful responses, associated with the body object
//        let successes: [(object: E, response: NetworkResponse)]
//
//        /// Failed responses, associated with the body object
//        let failures: [(object: E, error: Error)]
//    }
//
//    public let session: Session
//
//    public var input: Result<[BodyRequest<E>]> = Result { throw ResultError.noResult }
//    public var output: Result<Outcome> = Result { throw ResultError.noResult }
//
//    let internalQueue = OperationQueue()
//    let dispatchQueue = DispatchQueue(label: "GroupBodyRequestNetworkOperation", qos: .background)
//
//    /// Create a new `DecodableResponseOperation`, parsing the response to a list of the given generic type.
//    ///
//    /// - Parameters:
//    ///   - requestable: A requestable describing the web resource to fetch.
//    ///   - session: The `URLSession` in which to perform the fetch (optional).
//    public init(bodyRequests: [BodyRequest<E>]? = nil, session: Session = URLSession.shared) {
//        self.session = session
//        if let bodyRequests = bodyRequests {
//            input = .success(bodyRequests)
//        }
//        super.init()
//    }
//
//    open override func execute() {
//        switch input {
//        case .success(let requestables):
//
//            var successes: [(E, NetworkResponse)] = []
//            var failures: [(E, Error)] = []
//
//            let group = DispatchGroup()
//
//            let operations: [NetworkOperation] = requestables.map { requestable in
//                group.enter()
//
//                let operation = NetworkOperation(requestable: requestable.request, session: self.session)
//
//                operation.addResultBlock { result in
//                    self.dispatchQueue.async {
//                        switch result {
//                        case .success(let response):
//                            successes.append((requestable.body, response))
//                        case .failure(let error):
//                            failures.append((requestable.body, error))
//                        }
//                        group.leave()
//                    }
//                }
//                return operation
//            }
//
//            self.internalQueue.addOperations(operations, waitUntilFinished: false)
//            group.wait()
//            self.output = .success(Outcome(successes: successes, failures: failures))
//            finish()
//
//        case .failure(let error):
//            output = .failure(error)
//            finish()
//        }
//    }
//}
