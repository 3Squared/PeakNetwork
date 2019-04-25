//
//  JSONAPI.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 25/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

/// A type that represents a JSON web API.
public protocol JSONAPI: API {
    
    /// The `JSONEncoder` used to encode request bodies.
    var encoder: JSONEncoder { get }
    
    /// The `JSONDecoder` used to decode response bodies.
    var decoder: JSONDecoder { get }
}

public extension JSONAPI {
    
    var encoder: JSONEncoder { return JSONEncoder() }
    var decoder: JSONDecoder { return JSONDecoder() }
    
    /// Create a `Resource` pointing to the provided path, with an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    func resource<E: Encodable>(path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], method: HTTPMethod, body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
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
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    /// - Returns: A configured `Resource`.
    func resource<D: Decodable>(path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], method: HTTPMethod, customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            decoder: decoder
        )
    }
    
    
    /// Create a `Resource` pointing to the provided path, with a decodable response body and an encodable HTTP body.
    ///
    /// - Parameters:
    ///   - path: The path of the `Resource`, relative to the `API`'s `baseURL`.
    ///   - queryItems: Query items for the request.
    ///   - headers: HTTP headers for the request.
    ///   - method: The HTTP method with which to perform the request.
    ///   - body: An `Encodable` object to be used as the HTTP request body.
    /// - Returns: A configured `Resource`.
    func resource<E: Encodable, D: Decodable>(path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:], method: HTTPMethod, body: E, customise: URLComponentsCustomisationBlock? = nil) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, queryItems: queryItems, customise: customise),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            body: body,
            encoder: encoder,
            decoder: decoder
        )
    }
}
