//
//  Errors.swift
//  Hubble
//
//  Created by Sam Oakley on 13/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation


/// Used when an error occurs converting Data to JSON.
public enum SerializationError: Error {
    /// The provided data cannot be converted to JSON.
    case invalid
}


/// Used when a server error occurs.
public enum ServerError: Error {
    /// The server responsed with a 401.
    case authentication
    /// The server responsed with a status code outside the range 200-300.
    case unknown(HTTPURLResponse)
}
