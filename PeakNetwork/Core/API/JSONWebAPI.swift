//
//  JSONAPI.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 25/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

/// A type that represents a JSON web API.
public protocol JSONWebAPI: WebAPI {
    
    /// The `JSONEncoder` used to encode request bodies.
    var encoder: JSONEncoder { get }
    
    /// The `JSONDecoder` used to decode response bodies.
    var decoder: JSONDecoder { get }
}

public extension JSONWebAPI {
    
    var encoder: JSONEncoder { return JSONEncoder() }
    var decoder: JSONDecoder { return JSONDecoder() }
    
    /// Create a `Resource` pointing to the provided path, with an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - method: The HTTP method with which to perform the request.
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    func resource<E: Encodable>(_ method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<Void> {
        return Resource(
            method: method,
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(self.headers) { current, _ in current },
            body: body,
            encoder: encoder
        )
    }
    
    
    /// Create a `Resource` pointing to the provided path, with a decodable response body.
    ///
    /// - Parameters:
    ///   - method: The HTTP method with which to perform the request.
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    /// - Returns: A configured `Resource`.
    func resource<D: Decodable>(_ method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            method: method,
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(self.headers) { current, _ in current },
            decoder: decoder
        )
    }
    
    
    /// Create a `Resource` pointing to the provided path, with a decodable response body and an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - method: The HTTP method with which to perform the request.
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    func resource<E: Encodable, D: Decodable>(_ method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            method: method,
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(self.headers) { current, _ in current },
            body: body,
            encoder: encoder,
            decoder: decoder
        )
    }
}
