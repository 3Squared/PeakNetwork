//
//  Recording.swift
//  PeakNetwork-iOS
//
//  Created by Luke Stringer on 06/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

public struct Recording: Codable {
    public struct Times: Codable {
        let start: Date
        let end: Date
    }
    
    public typealias Headers = [String: String]
    
    public struct Request: Codable {
        let headers: Headers?
        let body: String?
    }
    
    public struct Response: Codable {
        let status: Int
        let headers: Headers
        let body: String?
    }
    
    let method: String
    let host: String?
    let path: String
    let query: String?
    let times: Times
    
    let request: Request
    let response: Response?
}

extension Recording.Request {
    init(urlRequest: URLRequest) {
        let bodyString = urlRequest.httpBody.flatMap { String(data: $0, encoding: String.Encoding.utf8) }
        self.init(headers: urlRequest.allHTTPHeaderFields, body: bodyString)
    }
}

extension Recording.Response {
    init?(urlResponse: URLResponse?, data: Data?) {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            return nil
        }
        
        let responseBodyString = data.flatMap { String(data: $0, encoding: String.Encoding.utf8) }
        
        let responseHeaders = httpResponse.allHeaderFields
            
            // Map from AnyHashable:Any to String:String
            .compactMap { (key, value) -> [String: String]? in
                guard let stringKey = key as? String, let stringValue = value as? String else {
                    print("Cannot convert response headers to strings")
                    return nil
                }
                return [stringKey: stringValue]
                
            }
            
            // Reduce array of dictionaries into a single dictionary
            .reduce(Recording.Headers()) { (current, next) -> Recording.Headers in
                return current.merging(next) { (first, _) in first }
        }
        
        self.init(status: httpResponse.statusCode, headers: responseHeaders, body: responseBodyString)
    }
}
