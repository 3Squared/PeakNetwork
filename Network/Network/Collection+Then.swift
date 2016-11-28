//
//  Collection+Operations.swift
//  Hubble
//
//  Taken from ProcedureKit (https://github.com/ProcedureKit/ProcedureKit)
//
//  Created by Sam Oakley on 02/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation

public extension Collection where Iterator.Element: Operation {

    public func then<S: Sequence>(do sequence: S) -> [Iterator.Element] where S.Iterator.Element == Iterator.Element {
        var operations = Array(self)
        if let last = operations.last {
            assert(!last.isFinished, "Cannot add a finished operation as a dependency.")
            sequence.forEach { $0.add(dependency: last) }
        }
        operations += sequence
        return operations
    }
    
    public func then(do operations: Iterator.Element...) -> [Iterator.Element] {
        return then(do: operations)
    }
    
    func then(do block: () throws -> Iterator.Element?) rethrows -> [Iterator.Element] {
        guard let operations = try block() else { return Array(self) }
        return then(do: operations)
    }
    
    func enqueue(on queue: OperationQueue = OperationQueue()) {
        queue.addOperations(Array(self), waitUntilFinished: false)
    }
}
