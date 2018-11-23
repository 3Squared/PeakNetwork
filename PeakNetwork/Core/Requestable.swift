//
//  Requestable.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 21/11/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation


/// Implement this protocol to signify that the object can be converted into a `URLRequest`.
/// A common pattern is to implement this on an extension to an enum, describing your API endpoints.
public protocol Requestable {
    
    /// Return a `URLRequest` configured to represent the object.
    var request: URLRequest { get }
}

/// Creates a `Requestable` using a given block.
public class BlockRequestable: Requestable {
    
    /// :nodoc:
    public var request: URLRequest
    
    /// Create a new `BlockRequestable` with a given block.
    ///
    /// - Parameter block: A block returning a `URLRequest`.
    public init(_  block:  () -> URLRequest) {
        request = block()
    }
}

extension URLRequest: Requestable {
    public var request: URLRequest { return self }
}

extension URL: Requestable {
    public var request: URLRequest {
        return URLRequest(url: self)
    }
}
