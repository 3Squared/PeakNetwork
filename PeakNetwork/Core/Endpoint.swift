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
    let baseURL: String
    let path: String
    let queryItems: [URLQueryItem]
    let customise: URLComponentsCustomisationBlock?
    
    init(baseURL: String, path: String, queryItems: [URLQueryItem], customise: URLComponentsCustomisationBlock?) {
        self.baseURL = baseURL.hasSuffix("/") ? baseURL : (baseURL + "/")
        self.path = path.hasPrefix("/") ? String(path.dropFirst()) : path
        self.queryItems = queryItems
        self.customise = customise
    }
}

public extension Endpoint {
    var url: URL {
        var components = URLComponents(string: baseURL)!
        components.path = components.path + path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        customise?(&components)
        
        return components.url!
    }
}
