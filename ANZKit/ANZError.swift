//
//  ANZError.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public struct ANZError: ParsableObject {
    
    // httpStatus
    // serverDateTime
    
    public let code: String
    public let devDescription: String?
    public let sinceVersion: Int?
    public let httpStatus: Int?
    
    public init?(jsonDictionary: [String: Any]) {
        
        let parser = Parser(dictionary: jsonDictionary)
        
        do {
            self.code = try parser.fetch("code")
            self.devDescription = try parser.fetch("devDescription")
            self.sinceVersion = try parser.fetch("sinceVersion")
            self.httpStatus = try parser.fetch("httpStatus")
            
        } catch let error {
            print(error)
            return nil
        }
    }
}
