//
//  SearchResult.swift
//  NetworkExamples
//
//  Created by Sam Oakley on 23/05/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import Foundation

struct SearchResult: Codable {
    let description: String
    let url: URL
    let imageURL: URL
}
