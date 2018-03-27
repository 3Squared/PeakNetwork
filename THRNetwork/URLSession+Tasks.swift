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
    func dataTask<U: URLResponse>(forRequest request: URLRequest, completion: @escaping (Result<(Data?, U)>) -> Void) -> URLSessionTask {
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
                        throw ServerError.error(code: httpResponse.statusCodeEnum, response: httpResponse)
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
    func dataTask<D: Decodable, U: URLResponse>(forRequest request: URLRequest, decoder: JSONDecoder, completion: @escaping (Result<(D, U)>) -> Void) -> URLSessionTask {
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
                        throw ServerError.error(code: httpResponse.statusCodeEnum, response: httpResponse)
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


