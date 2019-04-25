//
//  Session.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 06/10/2016.
//  Copyright © 2016 3Squared. All rights reserved.
//

import Foundation

public typealias DataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

/// A protocol that mimics the functions on URLSession that we want to mock.
public protocol Session {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletionHandler) -> URLSessionDataTask
}

extension URLSession: Session { }
