//
//  WebService+API.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation
import PeakNetwork

extension WebService {
    
    enum GET: Requestable {
        
        case search(query: String)

        private var path: String {
            switch self {
            case .search(_): return "search"
            }
        }
        
        var request: URLRequest {
            
            var components = URLComponents(string: Constants.baseURL)!
            components.path += path
            
            switch self {
            case .search(let query):
                components.queryItems = [URLQueryItem(name: "search", value: query)]
                break
            }
        
            var urlRequest = URLRequest(url: components.url!)
            urlRequest.httpMethod = HTTPMethod.get.rawValue.uppercased()
            return urlRequest
        }
    }

}
