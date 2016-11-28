//
//  Operation+Then.swift
//  Hubble
//
//  Taken from ProcedureKit (https://github.com/ProcedureKit/ProcedureKit)
//
//  Created by Sam Oakley on 02/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation

public extension Operation {
    
    var operationName: String {
        return name ?? "Unnamed Operation"
    }
    
    func addCompletionBlock(block: @escaping () -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block()
            }
        }
        else {
            completionBlock = block
        }
    }

    func add(dependency: Operation) {
        addDependency(dependency)
    }
    
    func add(dependencies: Operation...) {
        add(dependencies: dependencies)
    }
    
    func add<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(add(dependency:))
    }
    
    func remove(dependency: Operation) {
        removeDependency(dependency)
    }
    
    func remove<Operations: Sequence>(dependencies: Operations) where Operations.Iterator.Element: Operation {
        dependencies.forEach(remove(dependency:))
    }
    
    func removeAllDependencies() {
        remove(dependencies: dependencies)
    }
    
    func then(do operation: Operation) -> [Operation] {
        assert(!isFinished, "Cannot add a finished operation as a dependency.")
        operation.add(dependency: self)
        return [self, operation]
    }
    
    func then(do block: () throws -> Operation?) rethrows -> [Operation] {
        guard let operation = try block() else { return [self] }
        return then(do: operation)
    }
    
    func enqueue(on queue: OperationQueue = OperationQueue()) {
        queue.addOperation(self)
    }
}
