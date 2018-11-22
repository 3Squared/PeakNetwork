//
//  RequestInterceptorSession.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 21/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

public typealias RequestInterceptor = (inout URLRequest) -> Void

public class RequestInterceptorSession: Session {
    
    private let session: Session
    private var interceptors: [RequestInterceptor] = []
    
    /// Create a new RequestInterceptorSession.
    ///
    /// - Parameters:
    ///   - session:
    ///   - interceptors: An array of RequestInterceptors to execute on each request made.
    public init(with session: Session, interceptors: [RequestInterceptor]) {
        self.session = session
        self.interceptors = interceptors
    }
    
    /// Create a new RequestInterceptorSession.
    ///
    /// - Parameters:
    ///   - session:
    ///   - interceptors: A RequestInterceptor to execute on each request made.
    public init(with session: Session, interceptor: @escaping RequestInterceptor) {
        self.session = session
        self.interceptors = [interceptor]
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask {
        
        var request = request
        interceptors.forEach { $0(&request) }
        
        return session.dataTask(with: request) { data, response, error in
            completionHandler(data, response, error)
        }
    }
    
    public func add(interceptor: @escaping RequestInterceptor) {
        interceptors.append(interceptor)
    }
}


public typealias ErrorInterceptor = (Data?, URLResponse?, Error) -> Void

public class ErrorInterceptorSession: Session {
    
    private let session: Session
    private var interceptors: [ErrorInterceptor] = []
    
    /// Create a new ErrorInterceptorSession.
    ///
    /// - Parameters:
    ///   - session:
    ///   - interceptors: An array of ErrorInterceptors to execute on each error received.
    public init(with session: Session, interceptors: [ErrorInterceptor]) {
        self.session = session
        self.interceptors = interceptors
    }
    
    /// Create a new ErrorInterceptorSession.
    ///
    /// - Parameters:
    ///   - session:
    ///   - interceptors: An ErrorInterceptor to execute on each error received.
    public init(with session: Session, interceptor: @escaping ErrorInterceptor) {
        self.session = session
        self.interceptors = [interceptor]
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask {
        
        return session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.interceptors.forEach { $0(data, response, error) }
            }
            completionHandler(data, response, error)
        }
    }
    
    public func add(interceptor: @escaping ErrorInterceptor) {
        interceptors.append(interceptor)
    }
}
