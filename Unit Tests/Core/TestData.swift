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
    let baseURL = URL("https://example.com/")
    let encoder: JSONEncoder = JSONEncoder()
    let decoder: JSONDecoder = JSONDecoder()
    let commonQueryItems = ["token": "hello"].queryItems
    let commonHeaders = ["user-agent": "peaknetwork"]
}

extension MyAPI {
    
    func simple() -> Resource<TestEntity> {
        return resource(path: "all", method: .get)
    }
    
    func complex(_ entity: TestEntity) -> Resource<Void> {
        return resource(path: "upload",
                        queryItems: ["token": "overridden", "search": "test"].queryItems,
                        headers: ["user-agent": "overridden", "device": "iphone"],
                        method: .put,
                        body: entity)
    }
    
    func complexWithResponse(_ entity: TestEntity) -> Resource<TestEntity> {
        return resource(path: "upload",
                        queryItems: ["token": "overridden", "search": "test"].queryItems,
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
