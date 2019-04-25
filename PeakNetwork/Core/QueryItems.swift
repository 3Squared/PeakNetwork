//
//  QueryItems.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 25/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

public extension Dictionary where Key == String, Value == String? {
    var queryItems: [URLQueryItem] {
        return map { key, value in
            URLQueryItem(name: key, value: value)
        }
    }
}

public extension Array where Element == URLQueryItem {
    func merging(_ other: [URLQueryItem], uniquingKeysWith uniquingBlock: @escaping ((Element, Element) throws -> Element)) rethrows -> [URLQueryItem] {
        let keys = Set((self + other).map { $0.name })
        return try keys.map { key in
            let selfValue = self.first { $0.name == key }
            let otherValue = other.first { $0.name == key }
            
            if let selfValue = selfValue, let otherValue = otherValue {
                return try uniquingBlock(selfValue, otherValue)
            } else {
                return (selfValue ?? otherValue)!
            }
        }
    }
}
