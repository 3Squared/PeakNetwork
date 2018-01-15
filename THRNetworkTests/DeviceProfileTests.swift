//
//  DeviceProfileTests.swift
//  THRNetwork
//
//  Created by Sam Oakley on 15/1/2018.
//  Copyright © 2018 Sam Oakley. All rights reserved.
//

import XCTest
@testable import THRNetwork

// These tests will only pass on an iPhone 8 11.1 Simulator
class DeviceProfileTests: XCTestCase {
   
    func testDeviceName() {
        XCTAssertEqual(DeviceProfile.deviceName, "iPhone Simulator")
    }
    
    func testDeviceVersion() {
        XCTAssertEqual(DeviceProfile.deviceVersion, "11.1")
    }
}
