//
//  WebService+Requests.swift
//  PeakNetworkExamples
//
//  Created by Sam Oakley on 23/5/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation
import PeakNetwork
import PeakResult
import PeakOperation

extension WebService {
    
    func search(for query: String, completion: @escaping (Result<[SearchResult]>) -> ()) {
        
        let network = NetworkOperation(requestable: GET.search(query: query), session: session)
        let decode = JSONDecodeOperation<[SearchResult]>(decoder: decoder)
        
        decode.addResultBlock(block: completion)

        network
            .passesResult(to: decode)
            .enqueue(on: queue)
    }
    
}
