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
