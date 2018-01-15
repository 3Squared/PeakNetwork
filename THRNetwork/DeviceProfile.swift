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
        return UIDevice.current.modelName
    }
    
    static var deviceVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var applicationVersion: String? {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        if identifier == "i386" || identifier == "x86_64" {
            return "\(UIDevice.current.model) Simulator"
        }
        
        return identifier
    }
}
