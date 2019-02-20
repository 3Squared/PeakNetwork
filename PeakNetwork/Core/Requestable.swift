//
//  Requestable.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 21/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation


/// Implement this protocol to signify that the object can be converted into a `URLRequest`.
/// A common pattern is to implement this on an extension to an enum, describing your API endpoints.
public protocol Requestable {
    
    /// Return a `URLRequest` configured to represent the object.
    var request: URLRequest { get }
}

/// Creates a `Requestable` using a given block.
public struct BlockRequestable: Requestable {
    
    /// :nodoc:
    public var request: URLRequest
    
    /// Create a new `BlockRequestable` with a given block.
    ///
    /// - Parameter block: A block returning a `URLRequest`.
    public init(_  block:  () -> URLRequest) {
        request = block()
    }
}

public struct Request: Requestable {
    
    public let url: URL
    public let query: [String: String]
    public let headers: [String: String]
    public let method: HTTPMethod
    
    init(_ url: URL,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        self.url = url
        self.query = query
        self.headers = headers
        self.method = method
    }
    
    init(_ string: String,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        
        self.init(URL(string: string)!,
                  query: query,
                  headers: headers,
                  method: method,
                  encoder: encoder)
    }
    
    init(_ base: String,
         path: String,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        self.init("\(base)/\(path)",
                  query: query,
                  headers: headers,
                  method: method,
                  encoder: encoder)
    }
    
    public var request: URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        let queryItems = query.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        if (!queryItems.isEmpty) {
            if components.queryItems == nil {
                components.queryItems = queryItems
            } else {
                components.queryItems!.append(contentsOf: queryItems)
            }
        }
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = method.rawValue.uppercased()
        
        headers.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        return urlRequest
    }
}


public struct BodyRequest<E: Encodable>: Requestable {
    
    public let body: E
    public let encoder: JSONEncoder
    private let internalRequest: Request
    
    init(_ url: URL,
         body: E,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        self.body = body
        self.encoder = encoder
        self.internalRequest = Request(url, query: query, headers: headers, method: method, encoder: encoder)
    }
    
    init(_ string: String,
         body: E,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        self.init(URL(string: string)!, body: body, query: query, headers: headers, method: method, encoder: encoder)
    }
    
    init(_ base: String,
         path: String,
         body: E,
         query: [String: String] = [:],
         headers: [String: String] = [:],
         method: HTTPMethod = .post,
         encoder: JSONEncoder = JSONEncoder()) {
        self.init("\(base)/\(path)",
            body: body,
            query: query,
            headers: headers,
            method: method,
            encoder: encoder)
    }
    
    public var request: URLRequest {
        var urlRequest = internalRequest.request
        urlRequest.httpBody = try! encoder.encode(body)
        return urlRequest
    }
}

extension URLRequest: Requestable {
    public var request: URLRequest { return self }
}

extension URL: Requestable {
    public var request: URLRequest {
        return URLRequest(url: self)
    }
}

extension String: Requestable {
    public var request: URLRequest {
        return URLRequest(url: URL(string: self)!)
    }
}
