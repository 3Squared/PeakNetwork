//
//  RetryingOperation.swift
//  Hubble
//
//  Created by Sam Oakley on 16/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation


/// A ConcurrentOperation with an added RetryStrategy. 
/// When the operation completes with an error Result, the StrategyBlock is used to determine if the operation should be attempted again.
/// This does not add a new operation, it simply restarts the original.
open class RetryingOperation<T>: ConcurrentOperation<T> {

    var failureCount = 0
    
    var retryStrategy = RetryStrategy.none
    
    public override func finish() {
        switch result() {
        case .failure(_):
            failureCount += 1
            if retryStrategy(failureCount) {
                start()
                return
            }
        default:
            break;
        }
        super.finish()
    }
}


/// Common retry strategies that can be used to determine if a RetryingOperation should retry on failure
class RetryStrategy {
    /// Takes the number of attempts and returns a boolean indicating whether to retry
    typealias StrategyBlock = (Int) -> Bool

    /// Don't retry
    static let none: StrategyBlock = { _ in return false }

    /// Retry N times. There is no delay between attempts.
    ///
    /// - Parameter times: number of times to retry.
    /// - Returns: a StrategyBlock
    static func retry(times: Int) -> StrategyBlock {
        return { attemptCount in return attemptCount <= times }
    }
}
