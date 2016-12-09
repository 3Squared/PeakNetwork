//
//  TestEntity.swift
//  Network
//
//  Created by Sam Oakley on 09/12/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation
import Network

struct TestEntity: JSONConvertible {
    let name: String
    
    init(fromJson json: JSON) throws {
        guard let name = json["name"] as? String
            else {
                throw SerializationError.invalid
        }
        
        self.name = name
   }
}
