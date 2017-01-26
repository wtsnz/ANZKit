//
//  PublicKey.swift
//  ANZ
//
//  Created by Will Townsend on 9/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

struct PublicKey: ParsableObject {
    
    // httpStatus
    // serverDateTime
    
    let key: String
    let id: String
    let validTo: String
    
    init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.id = try parser.fetch("publicKeyId")
            self.key = try parser.fetch("publicKey")
            self.validTo = try parser.fetch("validTo")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
