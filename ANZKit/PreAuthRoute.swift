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