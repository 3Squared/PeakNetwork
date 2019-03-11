//
//  Resources.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 03/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

// MARK: - Endpoints

public struct Endpoint {
    let baseURL: String
    let path: String
    let query: [String: String]
}


public extension Endpoint {
    var url: URL {
        var components = URLComponents(string: baseURL)!
        components.path = path
        components.queryItems = query.isEmpty ? nil : query.queryItems
        return components.url!
    }
}


extension Dictionary where Key == String, Value == String {
    var queryItems: [URLQueryItem] {
        return map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
    }
}


// MARK: - Resources

/// Holds a `URLRequest` and a closure that can be used to parse the response into the `ResponseType`.
public struct Resource<ResponseType> {
    var request: URLRequest
    let parse: (Data?) throws -> ResponseType
}


/// Errors returned on various resource failures.
///
/// - noData: The data returned was missing.
/// - invalidData: The data returned could not be parsed into the requested format.
public enum ResourceError: Error {
    case noData
    case invalidData
}


public extension Resource {
    
    /// Create a `Resource` for a given `URL` with a custom parse closure.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(url: URL, headers: [String: String], method: HTTPMethod, parse: @escaping (Data?) throws -> ResponseType) {
        request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        self.parse = parse
    }
    
    /// Create a `Resource` for a given `Endpoint` with a custom parse closure.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, parse: @escaping (Data?) throws -> ResponseType) {
        self.init(url: endpoint.url, headers: headers, method: method, parse: parse)
    }
}


public extension Resource where ResponseType == Void {
    
    /// Create a `Resource` for a given `URL` where the response is not parsed.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    init(url: URL, headers: [String: String], method: HTTPMethod) {
        self.init(url: url, headers: headers, method: method) { data in
            return ()
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response is not parsed.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod) {
        self.init(url: endpoint.url, headers: headers, method: method)
    }
    
    /// Create a `Resource` for a given `Endpoint` with a HTTP body where the response is not parsed.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - body: The `Encodable` object to use as the HTTP body.
    ///   - encoder: The `JSONEncoder` used to encode `body`.
    init<Body: Encodable>(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, body: Body, encoder: JSONEncoder) {
        self.init(endpoint: endpoint, headers: headers, method: method)
        request.httpBody = try! encoder.encode(body)
    }
}


public extension Resource where ResponseType: Decodable {
    
    /// Create a `Resource` for a given `URL` where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init(url: URL, headers: [String: String], method: HTTPMethod, decoder: JSONDecoder) {
        self.init(url: url, headers: headers, method: method) { data in
            if let data = data {
                return try decoder.decode(ResponseType.self, from: data)
            } else {
                throw ResourceError.noData
            }
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, decoder: JSONDecoder) {
        self.init(url: endpoint.url, headers: headers, method: method, decoder: decoder)
    }
    
    /// Create a `Resource` for a given `Endpoint` with a HTTP body where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    ///   - body: The `Encodable` object to use as the HTTP body.
    ///   - encoder: The `JSONEncoder` used to encode `body`.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init<Body: Encodable>(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, body: Body, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.init(endpoint: endpoint, headers: headers, method: method, decoder: decoder)
        request.httpBody = try! encoder.encode(body)
    }
}


public extension Resource where ResponseType: PeakImage {
    
    /// Create a `Resource` for a given `URL` where the response is expected to be a platform Image type.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    init(url: URL, headers: [String: String], method: HTTPMethod) {
        self.init(url: url, headers: headers, method: method) { data in
            if let data = data {
                if let image = ResponseType(data: data) {
                    return image
                } else {
                    throw ResourceError.invalidData
                }
            } else {
                throw ResourceError.noData
            }
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response is expected to be a platform Image type.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - method: The HTTP method to use.
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod) {
        self.init(url: endpoint.url, headers: headers, method: method)
    }
}


extension Resource {
    
    /// Create a new `NetworkOperation` initialised with the `Resource` and the provided `Session`.
    ///
    /// - Parameter session: The session in which to perform the request.
    /// - Returns: A `NetworkOperation` that will request the `Resource`.
    func operation(session: Session) -> NetworkOperation<ResponseType> {
        return NetworkOperation(resource: self, session: session)
    }
}



// MARK: - API

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
    public func resource(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query),
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
    public func endpoint(_ path: String, query: [String: String] = [:]) -> Endpoint {
        return Endpoint(baseURL: baseURL,
                        path: path,
                        query: query.merging(commonQuery) { current, _ in current })
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
    public func resource<E: Encodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get, body: E) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query),
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
    public func resource<D: Decodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, query: query),
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
    public func resource<E: Encodable, D: Decodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .post, body: E) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, query: query),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            body: body,
            encoder: encoder,
            decoder: decoder
        )
    }
}
