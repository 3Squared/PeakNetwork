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
       let request = setHeaders(on: request)
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            switch self.valid(response: response, error: error) {
            case .ok:
                completion(Result {
                    return (response as! T, data)
                })
            case .needsAuthentication:
                completion(Result { throw ServerError.authentication })
            case .server(let httpResponse):
                completion(Result { throw ServerError.unknown(httpResponse) })
            case .device(let error):
                completion(Result { throw error })
            }
        }
    }

    
    /// Create a URLSessionTask for an array of `Decodable` objects.
    ///
    /// - parameter request: A URLRequest
    /// - session: The `JSONDecoder` to use when decoding the response data (optional).
    /// - parameter completion: A completion block called with a Result containing an array of `Decodable`s.
    ///
    /// - returns: A new URLSessionTask.
    func dataTask<T: Decodable>(forRequest request: URLRequest, decoder: JSONDecoder, completion: @escaping (Result<[T]>) -> Void) -> URLSessionTask {
        let request = setHeaders(on: request)
        return dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            switch self.valid(response: response, error: error) {
            case .ok:
                if let data = data {
                    completion(Result {
                        do {
                            return try decoder.decode([T].self, from: data)
                        } catch {
                            return [try decoder.decode(T.self, from: data)]
                        }
                    })
                } else {
                    completion(Result {
                        throw SerializationError.noData
                    })
                }
            case .needsAuthentication:
                completion(Result { throw ServerError.authentication })
            case .server(let httpResponse):
                completion(Result { throw ServerError.unknown(httpResponse) })
            case .device(let error):
                completion(Result { throw error })
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


