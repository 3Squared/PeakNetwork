//
//  GitHubService.swift
//  Hubble
//
//  Created by Sam Oakley on 06/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import THRResult

// MARK: - Convenience methods on URLSession to return configured data tasks, used internally.
extension URLSession {
    
    /// Create a URLSessionTask for raw Data and URLResponse.
    ///
    /// - parameter request: A URLRequest
    /// - parameter completion:  A completion block called with a Result containing a URLResponse and Data
    ///
    /// - returns: A new URLSessionTask.
    func dataTask<T:URLResponse>(forRequest request: URLRequest, completion: @escaping (Result<(T, Data?)>) -> Void) -> URLSessionTask {
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            switch self.valid(response: response, error: error) {
            case .ok:
                completion(Result {
                    return (response as! T, data)
                })
            case .needsAuthentication:
                completion(Result { throw ServerError.authentication() })
            case .server(let httpResponse):
                completion(Result { throw ServerError.unknown(httpResponse) })
            case .device(let error):
                completion(Result { throw error })
            }
        }
    }
    
    /// Create a URLSessionTask for a single object conforming to JSONConstructable.
    ///
    /// - parameter request: A URLRequest
    /// - parameter completion:  A completion block called with a Result containing a JSONConstructable
    ///
    /// - returns: A new URLSessionTask.
    func dataTask<T:JSONConvertible>(forRequest request: URLRequest, completion: @escaping (Result<T>) -> Void) -> URLSessionTask {
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            switch self.valid(response: response, error: error) {
            case .ok:
                if let data = data, let json = try? self.json(from: data), let object = json as? [String: Any] {
                    completion(Result {
                        return try T(fromJson: object)
                    })
                } else {
                    completion(Result {
                        throw SerializationError.invalid
                    })
                }
            case .needsAuthentication:
                completion(Result { throw ServerError.authentication() })
            case .server(let httpResponse):
                completion(Result { throw ServerError.unknown(httpResponse) })
            case .device(let error):
                completion(Result { throw error })
            }
        }
    }
    
    /// Create a URLSessionTask for an array of objects conforming to JSONConstructable.
    ///
    /// - parameter request: A URLRequest
    /// - parameter completion:  A completion block called with a Result containing an array of JSONConstructables
    ///
    /// - returns: A new URLSessionTask.
    func dataTask<T:JSONConvertible>(forRequest request: URLRequest, completion: @escaping (Result<[T]>) -> Void) -> URLSessionTask {
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            switch self.valid(response: response, error: error) {
            case .ok:
                if let data = data, let json = try? self.json(from: data), let array = json as? [[String: Any]] {
                    completion(Result {
                        return try array.flatMap(T.init)
                    })
                } else {
                    completion(Result {
                        throw SerializationError.invalid
                    })
                }
            case .needsAuthentication:
                completion(Result { throw ServerError.authentication() })
            case .server(let httpResponse):
                completion(Result { throw ServerError.unknown(httpResponse) })
            case .device(let error):
                completion(Result { throw error })
            }
        }
    }
    
    
    func json(from data: Data) throws -> Any {
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
    
    func valid(response: URLResponse?, error: Error?) -> ResponseStatus {
        if let e = error {
            return .device(e)
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..<300:
                return .ok
            case 401:
                return .needsAuthentication
            default:
                return .server(httpResponse)
            }
        }
        return .ok
    }
    
    
    enum ResponseStatus {
        case ok
        case needsAuthentication
        case server(HTTPURLResponse)
        case device(Error)
    }
}


