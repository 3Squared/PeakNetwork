//
//  DeviceProfile.swift
//  Network
//
//  Created by Chris Goldsmith on 02/02/2017.
//  Copyright © 2017 3Squared. All rights reserved.
//

import Foundation
import UIKit

class DeviceProfile {
    static var deviceName: String {
        return UIDevice.current.model
    }
    
    static var deviceVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var applicationVersion: String? {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    }
}

