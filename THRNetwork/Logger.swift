//
//  Logger.swift
//  THRNetwork
//
//  Created by Sam Oakley on 08/06/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

/// Wrap any type of Session with additional Logging behavior.
/// The logger will be called when a request is made and a response is received.
public class LoggingSession: Session {
    
    private let session: Session
    private let logger: Logger

    /// Create a new LoggingSession.
    ///
    /// - Parameters:
    ///   - session:
    ///   - configure: Configure the session.
    public init(with session: Session, logger: Logger) {
        self.session = session
        self.logger = logger
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask {
        logger.request(request)
        return session.dataTask(with: request) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            strongSelf.logger.response(data: data, response: response, error: error)
            completionHandler(data, response, error)
        }
    }
}


/// Implement this protocol to create custom logging behavior for URLRequests and URLResponses.
public protocol Logger {
    
    /// Called when a request is made.
    ///
    /// - Parameter request
    func request(_ request: URLRequest)
    
    
    /// Called when a response is received.
    ///
    /// - Parameters:
    ///   - data
    ///   - response
    ///   - error
    func response(data: Data?, response: URLResponse?, error: Error?)
}


/// A basic logger that prints headers, bodies, and status codes.
/// Request and response bodies are printed as plain strings.
open class BasicLogger: Logger {
    
    let shouldLog: (URL?) -> Bool
    
    
    /// Create a new BasicLogger.
    ///
    /// - Parameters:
    ///     - shouldLog: Provide a block returning a bool to customise when log messages will be written.
    public init(shouldLog: @escaping (URL?) -> Bool = { _ in true }) {
        self.shouldLog = shouldLog
    }
    
    open func request(_ request: URLRequest) {
        guard shouldLog(request.url) else { return }
        
        print("⬆️ Request")
        print("\(request.httpMethod!.uppercased()) \(request.url!.absoluteString)")
        logBody(data: request.httpBody)
        logHeaders(request.allHTTPHeaderFields)
        print("\n")
    }
    
    open func response(data: Data?, response: URLResponse?, error: Error?) {
        guard shouldLog(response?.url) else { return }

        if let httpResponse = response as? HTTPURLResponse {
            print("\(httpResponse.statusCodeEnum.isSuccess && error == nil ? "✅" : "❌") Response")
            print("Code: \(httpResponse.statusCodeEnum)")
            logHeaders(httpResponse.allHeaderFields)
        } else {
            print("\(error == nil ? "✅" : "❌") Response")
        }

        if let response = response {
            print("\(response.url!.absoluteString)")
        }
        
        if let error = error {
            print("Error:\n\t\(error)")
        }
        
        logBody(data: data)
        print("\n")
    }
    
    
    /// Log out the request or response body.
    ///
    /// - Parameter data: The request or response body data.
    open func logBody(data: Data?) {
        if let data = data,
            let body = String(data: data, encoding: .utf8) {
            print("Body:")
            print("\(body)")
        }
    }
    
    
    /// Log out the request or response headers.
    ///
    /// - Parameter headers: The request or response headers.
    open func logHeaders(_ headers: [AnyHashable: Any]?) {
        if let headers = headers, headers.count > 0 {
            print("Headers: ")
            headers.forEach { (key, value) in
                print("\t\(key): \(value)")
            }
        }
    }
}

/// Request and response bodies are printed as formatted JSON.
open class JSONLogger: BasicLogger {
    
    let writingOptions: JSONSerialization.WritingOptions
    let readingOptions: JSONSerialization.ReadingOptions
    
    
    /// Create a new JSONLogger.
    ///
    /// - Parameters:
    ///     - readingOptions
    ///     - writingOptions
    ///     - shouldLog: Provide a block returning a bool to customise when log messages will be written.
    public init(readingOptions: JSONSerialization.ReadingOptions = [],
                writingOptions: JSONSerialization.WritingOptions = .prettyPrinted,
                shouldLog: @escaping (URL?) -> Bool = { _ in true }) {
        self.writingOptions = writingOptions
        self.readingOptions = readingOptions
        super.init(shouldLog: shouldLog)
    }
    
    override open func logBody(data: Data?) {
        if let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: readingOptions),
            let decodedData = try? JSONSerialization.data(withJSONObject: json, options: writingOptions),
            let body = String(data: decodedData, encoding: .utf8) {
            print("Body:")
            print("\(body)")
        }
    }
}
