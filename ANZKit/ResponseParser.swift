//
//  ResponseParser.swift
//  ANZ
//
//  Created by Will Townsend on 27/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public enum ResponseParserError: Error {
    
    case UnknownResponseFormat
    
}

public struct ResponseParser {
    
    static public func parseErrorResponse(responseData: Any?) throws -> ANZError {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let error = ANZError(jsonDictionary: json) else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        return error
        
    }
    
    static public func parseCurrentPublicKeyResponse(responseData: Any?) throws -> PublicKey {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let publicKey = PublicKey(jsonDictionary: json) else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        return publicKey
        
    }
    
    static public func parseAuthenticateTokenResponse(responseData: Any?) throws -> String {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let token = json["token"] as? String else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        return token
        
    }
    
    
    static public func parseSessionResponse(responseData: Any?) throws -> Session {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let session = Session(jsonDictionary: json) else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        return session
        
    }
    
}
