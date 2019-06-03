//
//  API.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation
import PeakNetwork

struct ExampleAPI: JSONWebAPI {
    let baseURL = URL("https://example.com/")
    let session = URLSession.mock
}

extension ExampleAPI {
    func search(_ query: String) -> NetworkOperation<[SearchResult]> {
        return operation(for: resource(.get, path: "search", queryItems: ["search": query].queryItems))
    }
}

struct SearchResult: Codable {
    let description: String
    let url: URL
    let imageURL: URL
}
