//
//  API.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 12/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

/// A type that represents a web API.
public protocol API {
    
    /// The base URL of the API. Paths will be appended to this.
    var baseURL: String { get }
    
    /// The session in which to perform generated requests.
    var session: Session { get }
    
    /// Common query items that will be added to every request.
    var commonQuery: [String: String] { get }
    
    /// Common HTTP headers that will be added to every request.
    var commonHeaders: [String: String] { get }
}


/// A type that represents a JSON web API.
public protocol JSONAPI: API {
    
    /// The `JSONEncoder` used to encode request bodies.
    var encoder: JSONEncoder { get }
    
    /// The `JSONDecoder` used to decode response bodies.
    var decoder: JSONDecoder { get }
}


public extension API {
    
    var commonQuery: [String: String] { return [:] }
    var commonHeaders: [String: String] { return [:] }
    var session: Session { return URLSession.shared }
    
    /// Create a new `NetworkOperation` initialised with the provided `Resource`.
    ///
    /// - Parameter resource: A resource to request.
    /// - Returns: A `NetworkOperation` configured with the provided `Resource` and shared API properties.
    public func operation<T>(for resource: Resource<T>) -> NetworkOperation<T> {
        return resource.operation(session: session)
    }
    
    
    /// Create a `Resource` pointing to the provided path.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - query: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    /// - Returns: A configured `Resource`.
    public func resource(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get, customise: URLComponentsCustomisationBlock? = nil) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method
        )
    }
    
    
    /// Create an `Endpoint` for the provided path.
    ///
    /// - Parameters:
    ///   - path: The path of the `Endpoint`, relative to the `API`'s `baseURL`.
    ///   - query: Query items for the request.
    /// - Returns: A configured `Endpoint`.
    public func endpoint(_ path: String, query: [String: String] = [:], customise: URLComponentsCustomisationBlock? = nil) -> Endpoint {
        return Endpoint(baseURL: baseURL,
                        path: path,
                        query: query.merging(commonQuery) { current, _ in current },
                        customise: customise)
    }
}


public extension JSONAPI {
    
    var encoder: JSONEncoder { return JSONEncoder() }
    var decoder: JSONDecoder { return JSONDecoder() }
    
    /// Create a `Resource` pointing to the provided path, with an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - query: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    public func resource<E: Encodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get, body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            body: body,
            encoder: encoder
        )
    }
    
    
    /// Create a `Resource` pointing to the provided path, with a decodable response body.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - query: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    /// - Returns: A configured `Resource`.
    public func resource<D: Decodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get, customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, query: query, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            decoder: decoder
        )
    }
    
    
    /// Create a `Resource` pointing to the provided path, with a decodable response body and an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - query: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    public func resource<E: Encodable, D: Decodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .post, body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, query: query, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            body: body,
            encoder: encoder,
            decoder: decoder
        )
    }
}
