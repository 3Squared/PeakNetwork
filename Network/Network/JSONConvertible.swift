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

/// Implement this protocol to signify that the object can be converted to, and from, a `JSONObject` (`[String: Any]`).
public protocol JSONConvertible {
    
    /// Create a new instance of the implementer from a given `JSONObject`.
    ///
    /// - Parameter json: A `JSONObject` describing the object.
    /// - Throws: If unable to deserialise the given JSONObject, an error should be thrown.
    init(fromJson json: JSONObject) throws
    
    /// Return a `JSONObject` which represents the object.
    var json: JSONObject { get }
}


public extension JSONConvertible {
    
    /// Returns an empty `JSONObject`.
    var json: JSONObject { return [:] }
}
