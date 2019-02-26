//
//  TestEntity.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 09/12/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation

#if os(iOS)

@testable import PeakNetwork_iOS

#else

@testable import PeakNetwork_macOS

#endif

struct TestEntity: Codable {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}
