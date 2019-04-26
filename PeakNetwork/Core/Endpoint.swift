//
//  Endpoint.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 12/03/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

public typealias URLComponentsCustomisationBlock = (inout URLComponents) -> ()

/// Describes an API endpoint.
public struct Endpoint {
    let baseURL: URL
    let path: String
    let queryItems: [URLQueryItem]
    let customise: URLComponentsCustomisationBlock?
    
    init(baseURL: URL, path: String, queryItems: [URLQueryItem], customise: URLComponentsCustomisationBlock?) {
        
        if !baseURL.absoluteString.hasSuffix("/") {
            preconditionFailure("Invalid baseURL (must end with \"/\"): \(path)")
        }
        
        if path.hasPrefix("/") {
            preconditionFailure("Invalid path component (must not start with \"/\"): \(path)")
        }
        
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems
        self.customise = customise
    }
}

public extension Endpoint {
    var url: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = components.path + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        customise?(&components)
        
        return components.url!
    }
}
