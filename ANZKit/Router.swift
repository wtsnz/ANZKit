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
    
    case publicKeys
    case authenticate(password: String, userId: String, publicKeyId: Int)
    
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
        
//        switch self {
//        case .createUser(let parameters):
//            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
//        case .updateUser(_, let parameters):
//            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
//        default:
//            break
//        }
        
        return urlRequest
    }
}
