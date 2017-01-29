//
//  ANZAPI.swift
//  ANZ
//
//  Created by Will Townsend on 9/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyRSA

extension Dictionary {
    func withAllValuesFrom(_ other: Dictionary) -> Dictionary {
        var result = self
        other.forEach { result[$0] = $1 }
        return result
    }
}

internal enum HTTPMethod: String {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}

internal enum BaseURL: String {
    case preAuth
    case standard
}

protocol RouteType {
    var requestProperties: (method: HTTPMethod, baseURL: BaseURL, path: String, parameters: [String: Any]?) { get }
}

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
            return (.get, .preAuth, "/publicKeys/current", nil)
            
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


public protocol ServerConfigType {
    var preAuthBaseUrl: URL { get }
    var baseUrl: URL { get }
}

internal extension ServerConfigType {
    
    func urlForBaseURL(baseURL: BaseURL) -> URL {
        switch baseURL {
        case .preAuth:
            return self.preAuthBaseUrl
        case .standard:
            return self.baseUrl
        }
    }
}

public struct ServerConfig: ServerConfigType {
    
    public let preAuthBaseUrl: URL
    public let baseUrl: URL
    
    public static let production: ServerConfigType = ServerConfig(
        preAuthBaseUrl: URL(string: "https://digital.anz.co.nz/preauth/web/api/v1")!,
        baseUrl: URL(string: "https://digital.anz.co.nz/api/v6")!
    )
    
}

protocol ServiceType {
    
    /// The configuration of the server
    var serverConfig: ServerConfigType { get }
    
    /// The id of the next request
    var requestId: Int { get }
    
    /// The client API key
    var apiKey: String { get }
    
    /// The clients user agent. Eg. 'goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/'
    var userAgent: String { get }
    
    /// The clients device description. Eg: 'SM-G900F'
    var deviceDescription: String { get }
    
    /// The android devices' API version. Eg. '19'
    var deviceApiVersion: String { get }
    
    /// The current access token.
    var accessToken: String? { get }
    
}

extension ServiceType {
    
    fileprivate var defaultHeaders: [String: String] {
        
        var headers = [String: String]()
        
        headers["User-Agent"] = self.userAgent
        headers["Android-Device-Description"] = self.deviceDescription
        headers["Android-Api-Version"] = self.deviceApiVersion
        headers["Api-Key"] = self.apiKey
        headers["Api-Request-Id"] = String(self.requestId)
        
        return headers
    }
    
    public func preparedRequest(forURL url: URL, method: HTTPMethod = .get, parameters: [String: Any]? = nil)
        -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            return self.preparedRequest(forRequest: request, parameters: parameters)
    }
    
    public func preparedRequest(forRequest originalRequest: URLRequest, parameters: [String: Any]? = nil)
        -> URLRequest {
            
            var request = originalRequest
            guard let URL = request.url else {
                return originalRequest
            }
            
            var headers = self.defaultHeaders
            
            let method = request.httpMethod?.uppercased()
            
            var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
            
            if let parameters = parameters {
                
                var queryItems = components.queryItems ?? []
                
                if method == .some("POST") || method == .some("PUT") {
                    if request.httpBody == nil {
                        headers["Content-Type"] = "application/json; charset=utf-8"
                        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
                    }
                } else {
//                    queryItems.append(
//                        contentsOf: query
//                            .flatMap(queryComponents)
//                            .map(URLQueryItem.init(name:value:))
//                    )
                }
                
                components.queryItems = queryItems.sorted { $0.name < $1.name }
                request.url = components.url
            }
            
            let currentHeaders = request.allHTTPHeaderFields ?? [:]
            request.allHTTPHeaderFields = currentHeaders.withAllValuesFrom(headers)
            
            return request
    }
    
    func request(route: RouteType) -> URLRequest {
        
        let properties = route.requestProperties
        let baseUrl = self.serverConfig.urlForBaseURL(baseURL: properties.baseURL)
        
        let URL = baseUrl.appendingPathComponent(properties.path)
        
        
        let request = self.preparedRequest(forURL: URL)
        
        return request
    }
    
}

public class ANZService: ServiceType {
    
    internal var serverConfig: ServerConfigType
    
    internal var requestId: Int
    
    internal var apiKey: String
    
    internal var userAgent: String
    
    internal var deviceDescription: String
    
    internal var deviceApiVersion: String
    
    public var accessToken: String?
    
    private static let session = URLSession(configuration: .default)
    
    public init(serverConfig: ServerConfigType, requestId: Int = 4200, apiKey: String, userAgent: String, deviceDescription: String, deviceApiVersion: String, accessToken: String? ) {
        self.serverConfig = serverConfig
        self.requestId = requestId
        self.apiKey = apiKey
        self.userAgent = userAgent
        self.deviceDescription = deviceDescription
        self.deviceApiVersion = deviceApiVersion
        self.accessToken = accessToken
    }
    

    public func publicKeys() {
        
        let route = PreAuthRoute.publicKeys
        let request = self.request(route: route)
        
        ANZService.session.dataTask(with: request) { (data, urlResponse, error) in
            
            print(data)
            print(urlResponse)
            print(error)
            
        }
        .resume()
        
        
    }
    
    
    
}

public class ANZAPI {
    
    let manager = Alamofire.SessionManager()
    
    public init() {
        
    }
    
    public func currentPublicKey() -> Observable<PublicKey> {
        
        return Observable.create({ [unowned self] observer in
            
            let request = self.manager
                .request(AuthenticationAPIRouter.publicKeys)
                .validate()
                .responseJSON { response in
                    
                    do {
                        let publicKey = try ResponseParser.parseCurrentPublicKeyResponse(responseData: response.result.value)
                        observer.on(.next(publicKey))
                        observer.on(.completed)
                    } catch (let error) {
                        observer.on(.error(error))
                        observer.on(.completed)
                    }
            }
            
            return Disposables.create {
                request.cancel()
            }
        })
    }
    
    public func authenticate(withUsername username: String, password: String) -> Observable<String> {
        return self.currentPublicKey()
            .flatMap { (publicKey) in
                return self.authenticate(userId: username, password: password, publicKey: publicKey)
            }
    }
    
    fileprivate func authenticate(userId: String, password: String, publicKey: PublicKey) -> Observable<String> {
        
        return Observable.create({ [unowned self] observer in
            
            guard let encryptedPassword = self.encryptString(string: password, withPublicKey: publicKey) else {
                
                observer.on(.error(ResponseParserError.UnknownResponseFormat))
                observer.on(.completed)
                
                return Disposables.create()
            }
            
            let method = AuthenticationAPIRouter.AuthenticationMethod.usernamePassword(password: encryptedPassword, userId: userId, publicKeyId: publicKey.id)
            
            let request = self.manager
                .request(AuthenticationAPIRouter.authenticate(method: method))
                .validate()
                .responseJSON { response in
                    
                    do {
                        let publicKey = try ResponseParser.parseAuthenticateTokenResponse(responseData: response.result.value)
                        observer.on(.next(publicKey))
                        observer.on(.completed)
                    } catch (let error) {
                        observer.on(.error(error))
                        observer.on(.completed)
                    }
            }
            
            return Disposables.create {
                request.cancel()
            }
            
        })
        
    }
    
    
    
}

// MARK: - Encryption

extension ANZAPI {
    
    public func encryptString(string: String, withPublicKey publicKey: PublicKey) -> String? {
        return try? SwiftyRSA.encryptString(string, publicKeyPEM: publicKey.key)
    }
    
}

