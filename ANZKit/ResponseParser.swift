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
    case FailedToDecrypt
    
}

public typealias NewDevice = (deviceKey: String, deviceToken: String)

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
    
    static public func parseAccountsResponse(responseData: Any?) throws -> [Account] {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let accountsArray = json["accounts"] as? [[String: Any]] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        let accounts = accountsArray.flatMap({ Account.init(jsonDictionary: $0) })
        
        return accounts
    }
    
    static internal func parseDevicesResponse(responseData: Any?) throws -> [Device] {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let devicesArray = json["devices"] as? [[String: Any]] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        let devices = devicesArray.flatMap({ Device.init(jsonDictionary: $0) })
        
        return devices
    }
    
    static internal func parseNewDeviceResponse(responseData: Any?, rsaUtils: ANZRSAUtils) throws -> NewDevice {
        
        guard let responseData = responseData else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let json = responseData as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let newDevice = json["newDevice"] as? [String: Any] else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let deviceKey = newDevice["key"] as? String else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let encryptedDeviceToken = newDevice["deviceToken"] as? String else {
            throw ResponseParserError.UnknownResponseFormat
        }
        
        guard let deviceToken = rsaUtils.decryptBase64String(encryptedBase64String: encryptedDeviceToken) else {
            throw ResponseParserError.FailedToDecrypt
        }
        
        return (deviceKey: deviceKey, deviceToken: deviceToken)
    }
    
}
