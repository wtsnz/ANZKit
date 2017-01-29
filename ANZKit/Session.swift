//
//  Session.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct Session: ParsableObject {
    
    // httpStatus
    // serverDateTime
    
    public let id: Int
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.id = try parser.fetch("ibSessionId")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
