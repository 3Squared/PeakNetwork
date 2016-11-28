//
//  JSONConstructable.swift
//  Hubble
//
//  Created by Sam Oakley on 19/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]

/// Implement this protocol to signify that the object can be initialised with a JSON dictionary
public protocol JSONConvertible {
    init(fromJson json: JSON) throws
    var json: JSON { get }
}

public extension JSONConvertible {
    var json: JSON { return [:] }
}
