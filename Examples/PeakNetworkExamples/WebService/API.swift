//
//  API.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation
import PeakNetwork
import PeakResult

struct API: APIProtocol {
    let baseURL = "https://example.com"
    let session = URLSession.mock
}

extension API {
    func search(_ query: String) -> NetworkOperation<[SearchResult]> {
        return operation(for: resource(path: "/search", query: ["search": query]))
    }
}

struct SearchResult: Codable {
    let description: String
    let url: URL
    let imageURL: URL
}
