//
//  Resources.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 03/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

public struct Resource<ResponseType> {
    var request: URLRequest
    let parse: (Data?) throws -> ResponseType
}

public enum ResourceError: Error {
    case noData
    case invalidData
}

public extension Resource {
    
    init(url: URL, headers: [String: String], method: HTTPMethod, parse: @escaping (Data?) throws -> ResponseType) {
        request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        self.parse = parse
    }
    
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, parse: @escaping (Data?) throws -> ResponseType) {
        self.init(url: endpoint.url, headers: headers, method: method, parse: parse)
    }
}

public extension Resource where ResponseType == Void {
    
    init(url: URL, headers: [String: String], method: HTTPMethod) {
        self.init(url: url, headers: headers, method: method) { data in
            return ()
        }
    }

    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod) {
        self.init(url: endpoint.url, headers: headers, method: method)
    }
    
    init<Body: Encodable>(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, body: Body, encoder: JSONEncoder) {
        self.init(endpoint: endpoint, headers: headers, method: method)
        request.httpBody = try! encoder.encode(body)
    }
}

public extension Resource where ResponseType: Decodable {
    
    init(url: URL, headers: [String: String], method: HTTPMethod, decoder: JSONDecoder) {
        self.init(url: url, headers: headers, method: method) { data in
            if let data = data {
                return try decoder.decode(ResponseType.self, from: data)
            } else {
                throw ResourceError.noData
            }
        }
    }
    
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, decoder: JSONDecoder) {
        self.init(url: endpoint.url, headers: headers, method: method, decoder: decoder)
    }
    
    init<Body: Encodable>(endpoint: Endpoint, headers: [String: String], method: HTTPMethod, body: Body, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.init(endpoint: endpoint, headers: headers, method: method, decoder: decoder)
        request.httpBody = try! encoder.encode(body)
    }
}

public extension Resource where ResponseType: PeakImage {
    
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
    
    init(endpoint: Endpoint, headers: [String: String], method: HTTPMethod) {
        self.init(url: endpoint.url, headers: headers, method: method)
    }
}

public protocol API {
    var scheme: String { get }
    var host: String { get }
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
    var commonQuery: [String: String] { get }
    var commonHeaders: [String: String] { get }
}

public extension API {
    
    var commonQuery: [String: String] { return [:] }
    var commonHeaders: [String: String] { return [:] }
    
    public func resource(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method
        )
    }
    
    public func resource<E: Encodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get, body: E) -> Resource<Void> {
        return Resource(
            endpoint: endpoint(path, query: query),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            body: body,
            encoder: encoder
        )
    }
    
    public func resource<D: Decodable>(path: String, query: [String: String] = [:], headers: [String: String] = [:], method: HTTPMethod = .get) -> Resource<D> {
        return Resource(
            endpoint: endpoint(path, query: query),
            headers: headers.merging(commonHeaders) { current, _ in current },
            method: method,
            decoder: decoder
        )
    }

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

    func endpoint(_ path: String, query: [String: String] = [:]) -> Endpoint {
        return Endpoint(scheme: scheme,
                        host: host,
                        path: path,
                        query: query.merging(commonQuery) { current, _ in current })
    }
}

public struct Endpoint {
    let scheme: String
    let host: String
    let path: String
    let query: [String: String]
}

public extension Endpoint {
    var url: URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
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
