//
//  JSONConstructable.swift
//  Hubble
//
//  Created by Sam Oakley on 19/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation

public typealias JSONObject = [String: Any]
public typealias JSONArray = [Any]

/// Implement this protocol to signify that the object can be initialised with a JSON object
public protocol JSONConvertible {
    init(fromJson json: JSONObject) throws
    var json: JSONObject { get }
}

public extension JSONConvertible {
    var json: JSONObject { return [:] }
}
