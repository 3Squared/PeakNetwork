//
//  Service.swift
//  THRNetwork
//
//  Created by Sam Oakley on 06/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import THRResult

public typealias DataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

/// A protocol that mimics the functions on URLSession that we want to mock.
public protocol Session {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask
}


/// This describes a mocked response.
public struct MockResponse {
    let data: Data
    let error: Error?
    let statusCode: HTTPStatusCode?
    let responseHeaders: [String: String]
    let sticky: Bool
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
                              encoder: JSONEncoder = JSONEncoder(),
                              isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.init(data: try! encoder.encode(json),
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
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
                              encoder: JSONEncoder = JSONEncoder(),
                              isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.init(data: try! encoder.encode(json),
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
                  isValid: isValid)
    }
    
    /// Create a new `MockResponse` from the contents of a given file iincluded in the bundle.
    ///
    /// - Parameters:
    ///   - fileName: The name of a JSON file included in the bundle.
    ///   - error: An optional error to pass back.
    ///   - statusCode: The status code of the response.
    ///   - responseHeaders: Headers to be returned in the response.
    ///   - sticky: By default (false) responses are returned once and removed. Set this to true to keep the response around forever when you want the same data to always be returned for a call.
    ///   - isValid: A block used to determine if a response should be returned for a given request. Return true to indicate that this response should be used.
    public init(fileName: String,
                statusCode: HTTPStatusCode? = .ok,
                responseHeaders: [String: String] = [:],
                error: Error? = nil,
                sticky: Bool = false,
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        let path = Bundle.allBundles.path(forResource: fileName, ofType: "json")!
        let data = try! NSData(contentsOfFile: path) as Data
        self.init(data: data,
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
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
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        
        self.init(data: jsonString.data(using: .utf8)!,
                  statusCode: statusCode,
                  responseHeaders: responseHeaders,
                  error: error,
                  sticky: sticky,
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
                isValid: @escaping (URLRequest) -> Bool = { _ in true }) {
        self.data = data
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.error = error
        self.sticky = sticky
        self.isValid = isValid
    }
}



/// A mock object implementing a shared interface with URLSession.
public class MockSession: Session {
    
    public typealias MockSessionConfigurationBlock = (MockSession) -> ()
    
    private var responses: [MockResponse] = []
    private var fallbackSession: Session?
    
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
        responses += [response]
    }
    
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask {
        
        let isValid: (_ response: MockResponse) -> Bool = { return $0.isValid(request) }
        
        guard let response = responses.first(where: isValid), let index = responses.index(where: isValid) else {
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
    
    final private class URLSessionDataTaskMock : URLSessionDataTask {
        
        let completionHandler: DataTaskCompletionHandler
        let taskResponse: MockResponse
        let request: URLRequest
        
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
                completionHandler(taskResponse.data, urlResponse, taskResponse.error)
            } else {
                completionHandler(taskResponse.data, nil, taskResponse.error)
            }
        }
        
        override func cancel() {
            // no-op
        }
    }
    
}


extension URLSession: Session { }

// MARK: - Convenience methods on URLSession to return configured data tasks, used internally.
public extension Session {
    
    /// Create a URLSessionTask for raw Data and URLResponse.
    ///
    /// - parameter request: A URLRequest
    /// - parameter completion:  A completion block called with a Result containing a URLResponse and Data
    ///
    /// - returns: A new URLSessionTask.
    public func dataTask<U: URLResponse>(with request: URLRequest, completion: @escaping (Result<(Data?, U)>) -> Void) -> URLSessionTask {
        let request = setHeaders(on: request)
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completion(Result { throw error })
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeEnum.isSuccess {
                    completion(Result {
                        return (data, response as! U)
                    })
                } else {
                    completion(Result {
                        throw ServerError.error(code: httpResponse.statusCodeEnum, data: data, response: httpResponse)
                    })
                }
            } else {
                completion(Result {
                    throw ServerError.unknownResponse
                })
            }
        }
    }
    
    
    /// Create a URLSessionTask for a `Decodable` object.
    ///
    /// - parameter request: A URLRequest
    /// - session: The `JSONDecoder` to use when decoding the response data (optional).
    /// - parameter completion: A completion block called with a Result containing an array of `Decodable`s.
    ///
    /// - returns: A new URLSessionTask.
    public func dataTask<D: Decodable, U: URLResponse>(with request: URLRequest, decoder: JSONDecoder, completion: @escaping (Result<(D, U)>) -> Void) -> URLSessionTask {
        let request = setHeaders(on: request)
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                completion(Result { throw error })
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCodeEnum.isSuccess {
                    if let data = data {
                        completion(Result {
                            return (try decoder.decode(D.self, from: data), response as! U)
                        })
                    } else {
                        completion(Result {
                            throw SerializationError.noData
                        })
                    }
                } else {
                    completion(Result {
                        throw ServerError.error(code: httpResponse.statusCodeEnum, data: data, response: httpResponse)
                    })
                }
            } else {
                completion(Result {
                    throw ServerError.unknownResponse
                })
            }
        }
    }
    
    
    
    private func setHeaders(on request: URLRequest) -> URLRequest {
        
        var request = request
        request.addValue(DeviceProfile.deviceName, forHTTPHeaderField: "X-Device")
        request.addValue(DeviceProfile.deviceVersion, forHTTPHeaderField: "X-DeviceVersion")
        if let appVersion = DeviceProfile.applicationVersion {
            request.addValue(appVersion, forHTTPHeaderField: "X-SoftwareVersion")
        }
        
        return request
    }
}


