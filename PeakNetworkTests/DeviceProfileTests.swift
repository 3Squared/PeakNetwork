//
//  DeviceProfileTests.swift
//  PeakNetwork
//
//  Created by Sam Oakley on 15/1/2018.
//  Copyright © 2018 3Squared. All rights reserved.
//

import XCTest
@testable import PeakNetwork

// These tests will only pass on an iPhone 8 11.1 Simulator
class DeviceProfileTests: XCTestCase {
   
    func testDeviceName() {
        XCTAssertEqual(DeviceProfile.deviceName, "iPhone Simulator")
    }
}
