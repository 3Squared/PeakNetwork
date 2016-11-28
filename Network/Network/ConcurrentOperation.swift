//
//  ConcurrentOperation.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation

open class ConcurrentOperation<T>: ResultOperation<T> {
    
    var _executing = false
    var _finished = false
    
    open func run() { }
    
    override open func start() {
        if isCancelled {
            notifyChanges(forKey: #keyPath(Operation.isFinished)) {
                _finished = true
            }
            return
        }
        
        notifyChanges(forKey: #keyPath(Operation.isExecuting)) {
            run()
            _executing = true
        }
    }

    
    private func notifyChanges(forKey key: String, changes: (Void) -> (Void)) {
        willChangeValue(forKey: key)
        changes()
        didChangeValue(forKey: key)
    }
    

    public func finish()  {
        willChangeValue(forKey: #keyPath(Operation.isFinished))
        willChangeValue(forKey: #keyPath(Operation.isExecuting))
        
        _executing = false
        _finished = true
        
        didChangeValue(forKey: #keyPath(Operation.isFinished))
        didChangeValue(forKey: #keyPath(Operation.isExecuting))
    }
        
    override open var isExecuting: Bool {
        return _executing
    }
    
    override open var isFinished: Bool {
        return _finished
    }
    
    override open var isConcurrent: Bool {
        return true
    }
}
