//
//  ResultOperation.swift
//  Hubble
//
//  Created by Sam Oakley on 14/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import THRResult

open class ResultOperation<T>: Operation, ProducesResult {
    open var operationResult: Result<T> = Result { throw ResultError.noResult }
    
    public func addResultBlock(block: @escaping (Result<T>) -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block(self.result())
            }
        }
        else {
            completionBlock = {
                block(self.result())
            }
        }
    }

    
    open func result() -> Result<T> {
        return operationResult
    }
}


open class BlockResultOperation<O>: ResultOperation<O> {
    let block: () -> (Result<O>)
    
    public init(_ block: @escaping () -> (O)) {
        self.block = {
            return Result { return block() }
        }
    }
    
    public init(_ block: @escaping () -> (Result<O>)) {
        self.block = block
    }
    
    open override func main() {
        self.operationResult = self.block()
    }
}
