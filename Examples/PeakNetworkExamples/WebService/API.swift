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

struct ExampleAPI: API {
    let scheme = "https"
    let host = "example.com"
    
    let encoder: JSONEncoder = JSONEncoder()
    let decoder: JSONDecoder = JSONDecoder()
    
    var commonHeaders = ["api_key": UUID().uuidString]
}

extension ExampleAPI {
    
    func search(_ query: String) -> Resource<[SearchResult]> {
        return resource(path: "/search", query: ["search": query])
    }
}

extension Resource {
    
    func enqueue(session: Session = URLSession.mock, _ completion: @escaping (Result<Response<ResponseType>>) -> ()) {
        let operation = NetworkOperation(resource: self, session: session)
        operation.addResultBlock(block: completion)
        operation.enqueue()
    }
}
