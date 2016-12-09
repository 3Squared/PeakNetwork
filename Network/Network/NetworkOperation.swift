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

open class NetworkOperation<T>: RetryingOperation<T> {
    internal var task: URLSessionTask?
    internal var taskMaker: (() -> (URLSessionTask))!
    
    open override func run() {
        task?.cancel()
        task = taskMaker()
        task?.resume()
    }
    
    override open func cancel() {
        task?.cancel()
    }
}

public protocol Requestable {
    var request: URLRequest { get }
}

public class URLRequestable: Requestable {
    public var request: URLRequest
    
    public init(_  url: URL) {
        request = URLRequest(url: url)
    }
}


public class BlockRequestable: Requestable {
    public var request: URLRequest
    
    public init(_  block:  () -> URLRequest) {
        request = block()
    }
}

public class RequestOperation<T:JSONConvertible>: NetworkOperation<T> {
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<T>) in
                self.operationResult = result
                self.finish()
            }
        }
    }
}

public class RequestManyOperation<J:JSONConvertible>: NetworkOperation<[J]> {
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request) { (result: Result<[J]>) in
                self.operationResult = result
                self.finish()
            }
        }
    }
}

public class URLResponseOperation: NetworkOperation<HTTPURLResponse> {
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (response, _) = try result.resolve()
                    self.operationResult = Result { return response }
                } catch {
                    self.operationResult = Result { throw error }
                }
                self.finish()
            }
        }
    }
}

public class DataOperation: NetworkOperation<Data> {
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (_, data) = try result.resolve()
                    if let d = data {
                        self.operationResult = Result { return d }
                    } else {
                        self.operationResult = Result { throw OperationError.noResult }
                    }
                } catch {
                    self.operationResult = Result { throw error }
                }
                self.finish()
            }
        }
    }
}

public class ImageOperation: NetworkOperation<UIImage> {
    public init(_ requestable: Requestable, session: URLSession = URLSession.shared) {
        super.init()
        taskMaker = {
            return session.dataTask(forRequest: requestable.request)  { (result: Result<(HTTPURLResponse, Data?)>) in
                do {
                    let (_, data) = try result.resolve()
                    if let d = data, let image = UIImage(data: d) {
                        self.operationResult = Result { return image }
                    } else {
                        self.operationResult = Result { throw OperationError.noResult }
                    }
                } catch {
                    self.operationResult = Result { throw error }
                }
                
                self.finish()
            }
        }
    }
}

