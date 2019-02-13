//
//  PeakNetwork+Aliases.swift
//  PeakNetwork
//
//  Created by Zack Brown on 08/02/2019.
//  Copyright © 2019 3Squared. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit

public typealias PeakImage = UIImage
typealias PeakImageView = UIImageView

#else

import AppKit

public typealias PeakImage = NSImage
typealias PeakImageView = NSImageView

#endif
