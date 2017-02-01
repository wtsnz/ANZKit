//
//  PreAuthRoute.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

internal enum PreAuthRoute: RouteType {
    
    public enum PreAuthMethod {
        case usernamePassword(password: String, userId: String, publicKeyId: Int)
        case deviceTokenPin(deviceToken: String, pin: String, publicKeyId: Int)
        case quickBalanceToken(quickBalanceToken: String, publicKeyId: Int)
    }
    
    case publicKeys
    case authenticate(method: PreAuthMethod)
    
    internal var requestProperties: (method: HTTPMethod, baseURL: BaseURL, path: String, parameters: [String: Any]?) {
        
        switch self {
        case .publicKeys:
            return (.get, .preAuth, "/publickeys/current", nil)
            
        case .authenticate(let method):
            
            let path = "/authenticate"
            var parameters: [String: Any]? = nil
            
            switch method {
            case .usernamePassword(let password, let userId, let publicKeyId):
                parameters = [
                    "password": password,
                    "userId": userId,
                    "publicKeyId": publicKeyId
                ]
            case .deviceTokenPin(let deviceToken, let pin, let publicKeyId):
                parameters = [
                    "deviceToken": deviceToken,
                    "pin": pin,
                    "publicKeyId": publicKeyId
                ]
            case .quickBalanceToken(let quickBalanceToken, let publicKeyId):
                parameters = [
                    "quickBalanceToken": quickBalanceToken,
                    "publicKeyId": publicKeyId
                ]
            }
            
            return (.post, .preAuth, path, parameters)
        }
    }
}


internal enum Route: RouteType {
    
    public enum SessionMethod {
        case withAccessToken
        case withAuthCode(authCode: String)
        case withDeviceToken(deviceToken: String, publicKeyId: Int)
    }
    
    /// Fetch the current session
    case sessions(method: SessionMethod)
    
    /// Fetch the list of accounts
    case accounts(showInvestmentSchemes: Bool)
    
    /// Fetch the list of devices
    case devices
    
    /// Registers a new device and sets the pin for the current DeviceId
    /// Must also send a valid publicKey so we can decrypt anything the server sends us.
    case setPin(pin: String, publicKeyId: Int, deviceName: String, devicePublicKey: String)
    
    internal var requestProperties: (method: HTTPMethod, baseURL: BaseURL, path: String, parameters: [String: Any]?) {
        
        switch self {

        case .sessions(let method):
            
            let path = "/sessions"
            var parameters: [String: Any]? = nil
            
            switch method {
            case .withAccessToken:
                break
            case .withAuthCode(let authCode):
                parameters = [
                    "authCode": authCode
                ]
            case .withDeviceToken(let deviceToken, let publicKeyId):
                parameters = [
                    "deviceToken": deviceToken,
                    "publicKeyId": publicKeyId
                ]
            }
            
            return (.post, .standard, path, parameters)
            
        case .accounts(let showInvestmentSchemes):
            
            let parameters: [String: Any] = [
                "showInvestmentSchemes": showInvestmentSchemes
            ]
            
            return (.get, .standard, "/accounts", parameters)
            
        case .devices:
            return (.get, .standard, "/devices", nil)
        
        case .setPin(let pin, let publicKeyId, let deviceName, let devicePublicKey):
        
            let parameters: [String: Any] = [
                "pin": pin,
                "publicKeyId": publicKeyId,
                "newDevice": [
                    "description": deviceName,
                    "publicKey": devicePublicKey
                ]
            ]
            
            return (.get, .standard, "/accounts", parameters)
        }
    }
}

