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
import RxCocoa
import SwiftyRSA

public class ANZService: ServiceType {
    
    enum ServiceError: Error {
        case couldNotParseJSON
        case apiError(error: ANZError)
    }
    
    internal var serverConfig: ServerConfigType
    
    private var _requestId: Int = 0
    internal var requestId: Int {
        get {
            let value = _requestId
            _requestId = _requestId + 1
            return value
        }
        set {
            self._requestId = newValue
        }
    }
    
    internal var apiKey: String
    
    internal var userAgent: String
    
    internal var deviceId: String
    
    internal var deviceDescription: String
    
    internal var deviceApiVersion: String
    
    public var accessToken: String?
    
    public var ibSessionId: String?
    
    private static let session = URLSession(configuration: .default)
    let scheduler: OperationQueueScheduler
    
    public init(serverConfig: ServerConfigType, requestId: Int = 4200, apiKey: String, userAgent: String, deviceId: String, deviceDescription: String, deviceApiVersion: String, accessToken: String?, ibSessionId: String?) {
        self.serverConfig = serverConfig
        self._requestId = requestId
        self.apiKey = apiKey
        self.userAgent = userAgent
        self.deviceId = deviceId
        self.deviceDescription = deviceDescription
        self.deviceApiVersion = deviceApiVersion
        self.accessToken = accessToken
        self.ibSessionId = ibSessionId
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        self.scheduler = OperationQueueScheduler(operationQueue: operationQueue)
    }
    
    fileprivate func jsonRequest(route: RouteType) -> Observable<Any> {
        return Observable.just(self.request(route: route))
            .flatMap({ (request) in
                return self.jsonRequest(request: request)
            })
    }
    
    fileprivate func jsonRequest(request: URLRequest) -> Observable<Any> {
        
        return ANZService.session.rx.response(request: request)
            .subscribeOn(self.scheduler)
            .flatMap({ (value) -> Observable<Data> in
                
                let response = value.0
                let data = value.1
                
                // The API assumes we always update the Access-Token that is provided in responses.
                if let accessToken = response.allHeaderFields["Access-Token"] as? String {
                    self.accessToken = accessToken
                }
                
                guard (200..<300).contains(response.statusCode),
                    let headers = response.allHeaderFields as? [String:String],
                    let contentType = headers["Content-Type"], contentType.hasPrefix("application/json")
                    else {
                        
                        guard let jsonData = try? JSONSerialization.jsonObject(with: value.1, options: []) else {
                            return Observable.error(ServiceError.couldNotParseJSON)
                        }
                        
                        guard let error = try? ResponseParser.parseErrorResponse(responseData: jsonData) else {
                            return Observable.error(ServiceError.couldNotParseJSON)
                        }
                        
                        return Observable.error(ServiceError.apiError(error: error))
                }
                
                return Observable.just(data)
            })
            
            .flatMap { (data) -> Observable<Any> in
                
                guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                
                return Observable.just(jsonData)
        }
    }
    
    fileprivate func authenticate(userId: String, password: String, publicKey: PublicKey) -> Observable<String> {

        guard let encryptedPassword = self.encryptString(string: password, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = PreAuthRoute.authenticate(method: .usernamePassword(password: encryptedPassword, userId: userId, publicKeyId: publicKey.id))
        let request = self.request(route: route)
        
        return self.jsonRequest(request: request)
            .flatMap { (jsonData) -> Observable<String> in
                
                guard let publicKey = try? ResponseParser.parseAuthenticateTokenResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                
                return Observable.just(publicKey)
        }
        
    }
}

extension ANZService {
    
    public func currentPublicKey() -> Observable<PublicKey> {
        
        let route = PreAuthRoute.publicKeys
        let request = self.request(route: route)
        
        return self
            .jsonRequest(request: request)
            .flatMap { (jsonData) -> Observable<PublicKey> in
                guard let publicKey = try? ResponseParser.parseCurrentPublicKeyResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(publicKey)
        }
    }
    
    public func authenticate(withUsername username: String, password: String) -> Observable<Session> {
        return self.currentPublicKey()
            .flatMap { (publicKey) in
                return self.authenticate(userId: username, password: password, publicKey: publicKey)
            }
            .do(onNext: { (accessToken) in
                self.accessToken = accessToken
            })
            .flatMap({ (authToken) in
                return self.getSession()
            })
    }
    
    public func getSession() -> Observable<Session> {
        
        let route = Route.sessions(method: Route.SessionMethod.withAccessToken)
        
        return self
            .jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<Session> in
                guard let session = try? ResponseParser.parseSessionResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(session)
        }
    }
    
    private func requestObservable(route: RouteType) -> Observable<URLRequest> {
        return Observable.just(self.request(route: route))
    }
    
    public func getSession(authCode: String) -> Observable<Session> {
        
        let route = Route.sessions(method: Route.SessionMethod.withAuthCode(authCode: authCode))

        return self.jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<Session> in
                guard let session = try? ResponseParser.parseSessionResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(session)
            }
            .do(onNext: { [weak self] (session) in
                self?.ibSessionId = session.ibSessionId
            })
    }
    
    public func getAccounts(showInvestmentSchemes: Bool = true) -> Observable<[Account]> {
        
        let route = Route.accounts(showInvestmentSchemes: showInvestmentSchemes)
        
        return self
            .jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<[Account]> in
                guard let accounts = try? ResponseParser.parseAccountsResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(accounts)
        }
    }
    
    public func getDevices() -> Observable<[Device]> {
        
        let route = Route.devices
        
        return self
            .jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<[Device]> in
                guard let devices = try? ResponseParser.parseDevicesResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(devices)
        }
    }
    
    /**
    public func setPin(pin: String, deviceDescription: String, devicePublicKey: String) -> Observable<[Device]> {
        
        let route = Route.setPin(pin: encryptedPin, publicKeyId: <#T##Int#>, deviceName: <#T##String#>, devicePublicKey: <#T##String#>)
        let request = self.request(route: route)
        
        return self
            .jsonRequest(request: request)
            .flatMap { (jsonData) -> Observable<[Device]> in
                guard let devices = try? ResponseParser.parseDevicesResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(devices)
        }
    }
    */
    
}

extension ANZService {
    
    public func encryptString(string: String, withPublicKey publicKey: PublicKey) -> String? {
        return try? SwiftyRSA.encryptString(string, publicKeyPEM: publicKey.key)
    }
    
}
