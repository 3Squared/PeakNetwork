//
//  MockSession.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 25/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

/// This describes a mocked response.
public struct MockResponse {
    let dataBlock: () -> Data
    let error: Error?
    let statusCode: HTTPStatusCode?
    let responseHeaders: [String: String]
    let sticky: Bool
    let delay: TimeInterval
    let isValid: (URLRequest) -> Bool
    
    /// Create a new `MockResponse` with a JSON-type array.
    ///
    /// - Parameters:
    ///   - json: The data to be returned in the response.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init<T: Encodable>(json: [T],
                              statusCode: HTTPStatusCode? = .ok,
                              responseHeaders: [String: String] = [:],
                              error: Error? = nil,
                              sticky: Bool = false,
                              delay: TimeInterval = 0,
                              encoder: JSONEncoder = JSONEncoder(),
                              isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.init(data: try! encoder.encode(json),
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  delay: delay,
                  isValid: isValid)
    }
    
    /// Create a new `MockResponse` with a JSON-type object.
    ///
    /// - Parameters:
    ///   - json: The data to be returned in the response.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init<T: Encodable>(json: [String: T],
                              statusCode: HTTPStatusCode? = .ok,
                              responseHeaders: [String: String] = [:],
                              error: Error? = nil,
                              sticky: Bool = false,
                              delay: TimeInterval = 0,
                              encoder: JSONEncoder = JSONEncoder(),
                              isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.init(data: try! encoder.encode(json),
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  delay: delay,
                  isValid: isValid)
    }
    
    /// Create a new `MockResponse` from the contents of a given file iincluded in the bundle.
    ///
    /// - Parameters:
    ///   - fileName: The name of a JSON file included in the bundle.
    ///   - bundle: The bundle to search for the file in. Defaults to `.main`.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init(fileName: String,
                bundle: Bundle = .main,
                statusCode: HTTPStatusCode? = .ok,
                responseHeaders: [String: String] = [:],
                error: Error? = nil,
                sticky: Bool = false,
                delay: TimeInterval = 0,
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        let path = bundle.path(forResource: fileName, ofType: "json")!
        let data = try! NSData(contentsOfFile: path) as Data
        self.init(data: data,
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  delay: delay,
                  isValid: isValid)
    }
    
    /// Create a new `MockResponse` from a JSON string.
    ///
    /// - Parameters:
    ///   - string: The data to be returned in the response.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init(jsonString: String,
                statusCode: HTTPStatusCode? = .ok,
                responseHeaders: [String: String] = [:],
                error: Error? = nil,
                sticky: Bool = false,
                delay: TimeInterval = 0,
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        
        self.init(data: jsonString.data(using: .utf8)!,
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  delay: delay,
                  isValid: isValid)
    }
    
    
    /// Create a new `MockResponse`.
    ///
    /// - Parameters:
    ///   - data: The data to be returned in the response.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init(data: Data = Data(),
                statusCode: HTTPStatusCode? = .ok,
                responseHeaders: [String: String] = [:],
                error: Error? = nil,
                sticky: Bool = false,
                delay: TimeInterval = 0,
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.init(dataBlock: { return data },
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  delay: delay,
                  isValid: isValid)
    }
    
    /// Create a new `MockResponse`.
    ///
    /// - Parameters:
    ///   - dataBlock: A block called to create the data to be returned in the response.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init(dataBlock: @escaping () -> Data,
                statusCode: HTTPStatusCode? = .ok,
                responseHeaders: [String: String] = [:],
                error: Error? = nil,
                sticky: Bool = false,
                delay: TimeInterval = 0,
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.dataBlock = dataBlock
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.error = error
        self.sticky = sticky
        self.delay = delay
        self.isValid = isValid
    }
}



/// A mock object implementing a shared interface with URLSession.
public class MockSession: Session {
    
    public typealias MockSessionConfigurationBlock = (MockSession) -> ()
    
    private var responses: [MockResponse] = []
    private var fallbackSession: Session?
    
    private let dispatchQueue = DispatchQueue(label: "MockSession", qos: .background)
    
    /// Create a new session.
    ///
    /// - Parameters:
    ///   - session: A session to fallback to, if no matching response is found.
    ///              Pass URLSession.shared to mock some calls but allow others to hit the web.
    ///   - configure: Configure the session.
    public init(fallbackToSession session: Session? = nil, configure: MockSessionConfigurationBlock? = nil) {
        configure?(self)
        fallbackSession = session
    }
    
    
    /// Queue up a new response.
    ///
    /// - Parameter response: A MockResponse.
    public func queue(response: MockResponse) {
        dispatchQueue.sync {
            responses += [response]
        }
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask {
        
        return dispatchQueue.sync {
            let isValid: (_ response: MockResponse) -> Bool = { return $0.isValid(request) }
            
            guard let response = responses.first(where: isValid), let index = responses.firstIndex(where: isValid) else {
                if let session = self.fallbackSession {
                    return session.dataTask(with: request, completionHandler: completionHandler)
                } else {
                    fatalError("No matching mock response found for the request (\(request))")
                }
            }
            
            if !response.sticky {
                responses.remove(at: index)
            }
            return URLSessionDataTaskMock(response, forRequest: request, completionHandler: completionHandler)
        }
    }
    
    final private class URLSessionDataTaskMock : URLSessionDataTask {
        
        let completionHandler: DataTaskCompletionHandler
        let taskResponse: MockResponse
        let request: URLRequest
        
        let _progress = Progress(totalUnitCount: 1)
        override var progress: Progress {
            return _progress
        }
        
        private let dispatchQueue = DispatchQueue(label: "URLSessionDataTaskMock", qos: .background)
        
        override var originalRequest: URLRequest { return request }
        override var currentRequest: URLRequest { return request }
        
        init(_ response: MockResponse, forRequest request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) {
            self.taskResponse = response
            self.request = request
            self.completionHandler = completionHandler
        }
        
        override func resume() {
            if let statusCode = taskResponse.statusCode {
                let urlResponse = HTTPURLResponse(url: request.url!,
                                                  statusCode: statusCode,
                                                  httpVersion: "1.1",
                                                  headerFields: taskResponse.responseHeaders)
                dispatchQueue.asyncAfter(deadline: .now() + taskResponse.delay) {
                    self.progress.completedUnitCount = 1
                    self.completionHandler(self.taskResponse.dataBlock(), urlResponse, self.taskResponse.error)
                }
            } else {
                dispatchQueue.asyncAfter(deadline: .now() + taskResponse.delay) {
                    self.progress.completedUnitCount = 1
                    self.completionHandler(self.taskResponse.dataBlock(), nil, self.taskResponse.error)
                }
            }
        }
        
        override func cancel() {
            // no-op
        }
    }
    
}
