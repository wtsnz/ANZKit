//
//  ResponseParserTests.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import XCTest

import ANZKit

class ResponseParserTests: XCTestCase {
    
    func testPublicKeysResponseParser() {

        let jsonData = jsonDataFor("current", ofType: "json")
        
        let currentPublicKey = try? ResponseParser.parseCurrentPublicKeyResponse(responseData: jsonData)

        XCTAssert(currentPublicKey != nil, "Public Key shouldn't be nil")
        
    }
    
    func testAuthenticateTokenResponseParser() {
        
        let jsonData = jsonDataFor("authenticate", ofType: "json")
        
        let token = try? ResponseParser.parseAuthenticateTokenResponse(responseData: jsonData)
        
        XCTAssert(token != nil, "Token shouldn't be nil")
        
    }

}
