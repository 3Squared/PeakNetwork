//
//  MapResultOperation.swift
//  Hubble
//
//  Created by Sam Oakley on 14/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import THRResult

open class MapResultOperation<I, O>: ResultOperation<O> {
    let block: (Result<I>) -> (Result<O>)
    
    public init(_ block: @escaping (Result<I>) -> (Result<O>)) {
        self.block = block
    }
    
    open override func main() {
        guard let previous = dependencies.last as? ResultOperation<I> else {
            operationResult = Result { throw ResultError.noResult }
            return
        }
        self.operationResult = self.block(previous.result())
    }
}
