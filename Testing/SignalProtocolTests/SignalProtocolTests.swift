//
//  SignalProtocolTests.swift
//  SignalProtocolTests
//
//  Created by Chris Ballinger on 6/26/16.
//
//

import XCTest
import SignalProtocolObjC

class SignalProtocolTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddress() {
        let address = SignalAddress(name: "test", deviceId: 1)
        XCTAssertNotNil(address)
    }
    
    
}
