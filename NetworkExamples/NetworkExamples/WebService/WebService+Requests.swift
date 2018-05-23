//
//  WebService+Requests.swift
//  NetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation
import THRNetwork
import THRResult
import THROperations

extension WebService {
    
    func search(for query: String, completion: @escaping (Result<([SearchResult], HTTPURLResponse)>) -> ()) {
        let operation = DecodableResponseOperation<[SearchResult]>(
            GET.search(query: query),
            decoder: decoder,
            session: session
        )
                
        operation.addResultBlock(block: completion)
        operation.enqueue(on: queue)
    }
    
}
