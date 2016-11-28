//
//  Operators.swift
//  Hubble
//
//  Created by Sam Oakley on 19/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation


infix operator ?=: NilCoalescingPrecedence

/// Define the operator ?= as follows:
/// If B can be cast to the same type as A
/// And A and B are not already equal
/// Then set A to equal B
/// Else do nothing
///
/// Useful when updating values from JSON, and when setting can cause undesired side effects.
///
/// - parameter a
/// - parameter b
public func ?= <X: Equatable, Y> (a: inout X?, b: Y?) {
    if let c = b as? X {
        if a != c { a = c }
    }
}
