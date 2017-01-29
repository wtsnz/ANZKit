//
//  Router.swift
//  ANZ
//
//  Created by Will Townsend on 9/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import Alamofire

public enum ANZAPIRouter: URLRequestConvertible {
    
    case session(authCode: String?)
//    case authenticate(password: String, userId: String, publicKeyId: Int)

    static let baseURLString = "https://digital.anz.co.nz/api/v6"
    
    var method: HTTPMethod {
        switch self {
            
        case .session:
            return .post

        }
    }
    
    var path: String {
        switch self {
            
        case .session:
            return "/session"

        }
    }
    
    var parameters: Parameters? {
        switch self {
        default:
            return nil
        }
    }
    
    // MARK: URLRequestConvertible
    
    public func asURLRequest() throws -> URLRequest {
        let url = try AuthenticationAPIRouter.baseURLString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        
        // Figure out the parameters
        
        switch self {
        case .session(let authCode):
            
            var parameters: [String: Any] = [:]
            
            if let authCode = authCode {
                parameters["authCode"] = authCode
            }
            
            urlRequest = try URLEncoding.httpBody.encode(urlRequest, with: parameters)

        }
        
        return urlRequest
    }
}


public enum AuthenticationAPIRouter: URLRequestConvertible {
    
    public enum AuthenticationMethod {
        case usernamePassword(password: String, userId: String, publicKeyId: Int)
        case deviceTokenPin(deviceToken: String, pin: String, publicKeyId: Int)
        case quickBalanceToken(quickBalanceToken: String, publicKeyId: Int)
    }
    
    case publicKeys
    case authenticate(method: AuthenticationMethod)
    
    static let baseURLString = "https://digital.anz.co.nz/preauth/web/api/v1"
    
    var method: HTTPMethod {
        switch self {
            
        case .publicKeys:
            return .get
        case .authenticate:
            return .post
        }
    }
    
    var path: String {
        switch self {
            
        case .publicKeys:
            return "/publickeys/current"
        case .authenticate:
            return "/authenticate"
        }
    }
    
    // MARK: URLRequestConvertible
    
    public func asURLRequest() throws -> URLRequest {
        let url = try AuthenticationAPIRouter.baseURLString.asURL()
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        switch self {
            
        case .authenticate(let method):
            
            switch method {
            case .usernamePassword(let password, let userId, let publicKeyId):
                
                let parameters: [String: Any] = [
                    "password": password,
                    "userId": userId,
                    "publicKeyId": publicKeyId
                ]
                urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            
            case .deviceTokenPin(let deviceToken, let pin, let publicKeyId):
                
                let parameters: [String: Any] = [
                    "deviceToken": deviceToken,
                    "pin": pin,
                    "publicKeyId": publicKeyId
                ]
                
                urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
            
            case .quickBalanceToken(let quickBalanceToken, let publicKeyId):
                
                let parameters: [String: Any] = [
                    "quickBalanceToken": quickBalanceToken,
                    "publicKeyId": publicKeyId
                ]
                
                urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
                
            }
        
        default:
            break
        }
        
        urlRequest.setValue("goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/", forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("SM-G900F", forHTTPHeaderField: "Android-Device-Description")
        urlRequest.setValue("19", forHTTPHeaderField: "Android-Api-Version")
        urlRequest.setValue("41b4c957-56c8-4f0a-9ed6-bab90a43fcf5", forHTTPHeaderField: "Api-Key")
        urlRequest.setValue("123", forHTTPHeaderField: "Api-Request-Id")
        //urlRequest.setValue("", forHTTPHeaderField: "")
        
        
        return urlRequest
    }
}
