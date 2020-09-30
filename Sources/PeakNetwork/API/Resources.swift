//
//  Resources.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 03/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import UIKit

/// Holds a `URLRequest` and a closure that can be used to parse the response into the `ResponseType`.
public struct Resource<ResponseBody> {
    public var request: URLRequest
    public let parse: (Data?) throws -> ResponseBody
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
    ///   - method: The HTTP method to use.
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(method: HTTPMethod, url: URL, headers: [String: String], parse: @escaping (Data?) throws -> ResponseBody) {
        request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        self.parse = parse
    }
    
    /// Create a `Resource` for a given `Endpoint` with a custom parse closure.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(method: HTTPMethod, endpoint: Endpoint, headers: [String: String], parse: @escaping (Data?) throws -> ResponseBody) {
        self.init(method: method, url: endpoint.url, headers: headers, parse: parse)
    }
}


public extension Resource where ResponseBody == Void {
    
    /// Create a `Resource` for a given `URL` where the response body is not returned.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    init(method: HTTPMethod, url: URL, headers: [String: String]) {
        self.init(method: method, url: url, headers: headers) { data in
            return ()
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response body is not returned.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(method: HTTPMethod, endpoint: Endpoint, headers: [String: String]) {
        self.init(method: method, url: endpoint.url, headers: headers)
    }
    
    /// Create a `Resource` for a given `Endpoint` with a HTTP body where the response body is not returned.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - body: The `Encodable` object to use as the HTTP body.
    ///   - encoder: The `JSONEncoder` used to encode `body`.
    init<Body: Encodable>(method: HTTPMethod, endpoint: Endpoint, headers: [String: String], body: Body, encoder: JSONEncoder) {
        self.init(method: method, endpoint: endpoint, headers: headers)
        request.httpBody = try! encoder.encode(body)
    }
}

public extension Resource where ResponseBody == Data {

    /// Create a `Resource` for a given `URL` where the response body is not parsed.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    init(method: HTTPMethod, url: URL, headers: [String: String]) {
        self.init(method: method, url: url, headers: headers) { data in
            if let data = data {
                return data
            } else {
                throw ResourceError.noData
            }
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response body is not parsed.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - parse: A parse closure to convert the response data to the required `ResponseType`.
    init(method: HTTPMethod, endpoint: Endpoint, headers: [String: String]) {
        self.init(method: method, url: endpoint.url, headers: headers)
    }
    
    /// Create a `Resource` for a given `Endpoint` with a HTTP body where the response body is not parsed.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - body: The `Encodable` object to use as the HTTP body.
    ///   - encoder: The `JSONEncoder` used to encode `body`.
    init<Body: Encodable>(method: HTTPMethod, endpoint: Endpoint, headers: [String: String], body: Body, encoder: JSONEncoder) {
        self.init(method: method, endpoint: endpoint, headers: headers)
        request.httpBody = try! encoder.encode(body)
    }

}

public extension Resource where ResponseBody: Decodable {
    
    /// Create a `Resource` for a given `URL` where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init(method: HTTPMethod, url: URL, headers: [String: String], decoder: JSONDecoder) {
        self.init(method: method, url: url, headers: headers) { data in
            if let data = data {
                return try decoder.decode(ResponseBody.self, from: data)
            } else {
                throw ResourceError.noData
            }
        }
    }
    
    /// Create a `Resource` for a given `Endpoint` where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init(method: HTTPMethod, endpoint: Endpoint, headers: [String: String], decoder: JSONDecoder) {
        self.init(method: method, url: endpoint.url, headers: headers, decoder: decoder)
    }
    
    /// Create a `Resource` for a given `Endpoint` with a HTTP body where the response is expected to be `Decodable`.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - endpoint: The `Endpoint` for the resource.
    ///   - headers: The HTTP headers for the request.
    ///   - body: The `Encodable` object to use as the HTTP body.
    ///   - encoder: The `JSONEncoder` used to encode `body`.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    init<Body: Encodable>(method: HTTPMethod, endpoint: Endpoint, headers: [String: String], body: Body, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.init(method: method, endpoint: endpoint, headers: headers, decoder: decoder)
        request.httpBody = try! encoder.encode(body)
    }
}


public extension Resource where ResponseBody: UIImage {
    
    /// Create a `Resource` for a given `URL` where the response is expected to be a platform Image type.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The `URL` of the resource.
    ///   - headers: The HTTP headers for the request.
    init(method: HTTPMethod, url: URL, headers: [String: String]) {
        self.init(method: method, url: url, headers: headers) { data in
            if let data = data {
                if let image = ResponseBody(data: data) {
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
    init(method: HTTPMethod, endpoint: Endpoint, headers: [String: String]) {
        self.init(method: method, url: endpoint.url, headers: headers)
    }
}


extension Resource {
    
    /// Create a new `NetworkOperation` initialised with the `Resource` and the provided `Session`.
    ///
    /// - Parameter session: The session in which to perform the request.
    /// - Returns: A `NetworkOperation` that will request the `Resource`.
    func operation(session: Session) -> NetworkOperation<ResponseBody> {
        return NetworkOperation(resource: self, session: session)
    }
}
