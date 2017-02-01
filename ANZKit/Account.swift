//
//  Account.swift
//  ANZ
//
//  Created by Will Townsend on 1/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct Account: ParsableObject {
    
    public let accountKey: String
    public let customerKey: String
    public let nickname: String
    public let balance: String
    public let hashedAccountNumber: String
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.accountKey = try parser.fetch("accountKey")
            self.customerKey = try parser.fetch("customerKey")
            self.nickname = try parser.fetch("nickname")
            self.balance = try parser.fetch("balance")
            self.hashedAccountNumber = try parser.fetch("hashedAccountNumber")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
