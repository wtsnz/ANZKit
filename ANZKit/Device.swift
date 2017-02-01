//
//  Device.swift
//  ANZ
//
//  Created by Will Townsend on 1/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct Device: ParsableObject {
    
    // httpStatus
    // serverDateTime
    
    public let deviceKey: String
    public let description: String
    public let registrationDate: String
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.deviceKey = try parser.fetch("deviceKey")
            self.description = try parser.fetch("description")
            self.registrationDate = try parser.fetch("registrationDateTime")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
