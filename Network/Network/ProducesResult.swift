//
//  ProducesResult.swift
//  Hubble
//
//  Created by Sam Oakley on 10/10/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation
import THRResult

public protocol ProducesResult: class {
    associatedtype T
    func result() -> Result<T>
}

public enum ResultError: Error {
    case noResult
}
