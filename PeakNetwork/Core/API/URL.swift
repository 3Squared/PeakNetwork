//
//  URL.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 26/04/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation

public extension URL {
    /// Initialize with a StaticString.
    ///
    /// Adapted from https://www.swiftbysundell.com/posts/constructing-urls-in-swift
    init(_ string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid static URL string: \(string)")
        }
        
        self = url
    }
}
