//
//  EncodeOperation.swift
//  PeakNetwork-iOS
//
//  Created by Sam Oakley on 21/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

import Foundation
import PeakOperation
import PeakResult

/// Convert an encodable input to JSON Data.
open class JSONEncodeOperation<E: Encodable>: MapOperation<E, Data> {
    
    public let encoder: JSONEncoder
    
    /// Create a new `JSONEncodeOperation`.
    ///
    /// - Parameters:
    ///   - input: An input `Encodable` (optional).
    ///   - decoder: The `JSONEncoder` to use when encoding the data (optional).
    public init(input: E? = nil,
                encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
        super.init(input: input)
    }
    
    override open func map(input: E) -> Result<Data> {
        return Result { try encoder.encode(input) }
    }
}

/// Convert an array of encodables to an array of the encoded Data.
open class JSONEncodeArrayOperation<E: Encodable>: MapOperation<[E], [Data]> {
    
    public let encoder: JSONEncoder
    
    /// Create a new `JSONEncodeArrayOperation`.
    ///
    /// - Parameters:
    ///   - input: An input `Encodable` (optional).
    ///   - decoder: The `JSONEncoder` to use when encoding the data (optional).
    public init(input: [E]? = nil,
                encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
        super.init(input: input)
    }
    
    open override func map(input: [E]) -> Result<[Data]> {
        return Result {
            return try input.map { encodable in
                return try encoder.encode(encodable)
            }
        }
    }
}
