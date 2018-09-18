//
//  Operators.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 19/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation

infix operator ?=: NilCoalescingPrecedence

/// Define the operator ?= as follows:
/// If B can be cast to the same type as A,
/// and A and B are not already equal,
/// then set A to equal B,
/// else do nothing.
///
/// Useful when updating values from JSON, and when setting can cause undesired side effects.
///
/// - Parameters:
///   - a: LHS
///   - b: RHS
public func ?= <X: Equatable, Y> (a: inout X?, b: Y?) {
    if let c = b as? X {
        if a != c { a = c }
    }
}
