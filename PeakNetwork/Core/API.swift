//
//  API.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 12/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

/// A type that represents a web API.
public protocol WebAPI {
    
    /// The base URL of the API. Paths will be appended to this.
    var baseURL: URL { get }
    
    /// The session in which to perform generated requests.
    var session: Session { get }
    
    /// Common query items that will be added to every request.
    var queryItems: [URLQueryItem] { get }
    
    /// Common HTTP headers that will be added to every request.
    var headers: [String: String] { get }
}

public extension WebAPI {
    
    var queryItems: [URLQueryItem] { return [] }
    var headers: [String: String] { return [:] }
    var session: Session { return URLSession.shared }
    
    /// Create a new `NetworkOperation` initialised with the provided `Resource`.
    ///
    /// - Parameter resource: A resource to request.
    /// - Returns: A `NetworkOperation` configured with the provided `Resource` and shared API properties.
    func operation<T>(for resource: Resource<T>) -> NetworkOperation<T> {
        return resource.operation(session: session)
    }
    
    
    /// Create a `Resource` pointing to the provided path.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    /// - Returns: A configured `Resource`.
    func resource(path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], method: HTTPMethod, customise: URLComponentsCustomisationBlock? = nil) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(self.headers) { current, _ in current },
            method: method
        )
    }
    
    
    /// Create an `Endpoint` for the provided path.
    ///
    /// - Parameters:
    ///   - path: The path of the `Endpoint`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    /// - Returns: A configured `Endpoint`.
    func endpoint(_ path: String, queryItems: [URLQueryItem] = [], customise: URLComponentsCustomisationBlock? = nil) -> Endpoint {
        return Endpoint(baseURL: baseURL,
                        path: path,
                        queryItems: queryItems + self.queryItems,
                        customise: customise)
    }
}
