//
//  TestEntity.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 09/12/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation

#if os(iOS)
@testable import PeakNetwork_iOS
#else
@testable import PeakNetwork_macOS
#endif

struct TestEntity: Codable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

struct MyAPI: JSONAPI {
    let baseURL = "https://example.com"
    let encoder: JSONEncoder = JSONEncoder()
    let decoder: JSONDecoder = JSONDecoder()
    let commonQuery = ["token": "hello"]
    let commonHeaders = ["user-agent": "peaknetwork"]
}

extension MyAPI {
    
    func simple() -> Resource<TestEntity> {
        return resource(path: "/all")
    }
    
    func complex(_ entity: TestEntity) -> Resource<Void> {
        return resource(path: "/upload",
                        query: ["token": "overridden", "search": "test"],
                        headers: ["user-agent": "overridden", "device": "iphone"],
                        method: .put,
                        body: entity)
    }
    
    func url(_ url: URL) -> Resource<Data> {
        return Resource<Data>(url: url, headers: [:], method: .get) { data in
            return data!
        }
    }
}
