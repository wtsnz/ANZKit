//
//  Balance.swift
//  ANZ
//
//  Created by Will Townsend on 11/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct Balance: ParsableObject {
    
    // httpStatus
    // serverDateTime
    
    public let hashedAccountNumber: String
    public let productName: String
    public let nickname: String
    public let balance: String
    public let available: String
    public let type: String
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.hashedAccountNumber = try parser.fetch("hashedAccountNumber")
            self.productName = try parser.fetch("productName")
            self.nickname = try parser.fetch("nickname")
            self.balance = try parser.fetch("balance")
            self.available = try parser.fetch("available")
            self.type = try parser.fetch("type")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
