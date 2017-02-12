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
    
    public enum ServiceError: Error {
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

    public var deviceToken: String? {
        
        get {
            return self.rsaUtils.deviceToken
        }
        set {
            self.rsaUtils.deviceToken = newValue
        }
        
    }
    
    /// Whether or not the service has a device token to attempt
    /// to fetch a session from the device token + pin
    public var hasDeviceToken: Bool {
        return self.deviceToken != nil
    }
    
    
    // TODO: Add to protocol and stub
    let rsaUtils = ANZRSAUtils(keychainAccessGroup: nil)

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
        
        // Create certificates
        
    }
    
    public func quickBalanceService() -> ANZService {
        return ANZService(
            serverConfig: self.serverConfig,
            requestId: self.requestId,
            apiKey: self.apiKey,
            userAgent: self.userAgent,
            deviceId: self.deviceId,
            deviceDescription: self.deviceDescription,
            deviceApiVersion: self.deviceApiVersion,
            accessToken: nil,//self.accessToken,
            ibSessionId: nil//self.ibSessionId
        )
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
    
    fileprivate func preAuthenticate(userId: String, password: String, publicKey: PublicKey) -> Observable<String> {

        guard let encryptedPassword = self.encryptString(string: password, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = PreAuthRoute.authenticate(method: .usernamePassword(password: encryptedPassword, userId: userId, publicKeyId: publicKey.id))
        
        return self.jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<String> in
                
                guard let publicKey = try? ResponseParser.parseAuthenticateTokenResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                
                return Observable.just(publicKey)
        }
        
    }
    
    fileprivate func preAuthenticate(deviceToken: String, pin: String, publicKey: PublicKey) -> Observable<String> {
        
        guard let encryptedPin = self.encryptString(string: pin, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        guard let encryptedDeviceToken = self.encryptString(string: deviceToken, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = PreAuthRoute.authenticate(method: .deviceTokenPin(deviceToken: encryptedDeviceToken, pin: encryptedPin, publicKeyId: publicKey.id))
        
        return self.jsonRequest(route: route)
            .flatMap({ (jsonData) -> Observable<String> in
                guard let token = try? ResponseParser.parseAuthenticateTokenResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(token)
            })
    }
    
    fileprivate func preAuthenticate(quickBalanceToken: String, publicKey: PublicKey) -> Observable<String> {
        
        guard let encryptedQuickBalanceToken = self.encryptString(string: quickBalanceToken, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = PreAuthRoute.authenticate(method: .quickBalanceToken(quickBalanceToken: encryptedQuickBalanceToken, publicKeyId: publicKey.id))
        
        return self.jsonRequest(route: route)
            .flatMap({ (jsonData) -> Observable<String> in
                guard let token = try? ResponseParser.parseAuthenticateTokenResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(token)
            })
    }
}

extension ANZService {
    
    public func currentPublicKey() -> Observable<PublicKey> {
        
        let route = PreAuthRoute.publicKeys
        
        return self
            .jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<PublicKey> in
                guard let publicKey = try? ResponseParser.parseCurrentPublicKeyResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(publicKey)
        }
    }
    
    public func session(withDeviceToken deviceToken: String, pin: String) -> Observable<Session> {
        
        return self.currentPublicKey()
            .flatMap { (publicKey) in
                return self.preAuthenticate(deviceToken: deviceToken, pin: pin, publicKey: publicKey)
            }
            .do(onNext: { (accessToken) in
                self.accessToken = accessToken
            })
            .flatMap({ (accessToken) in
                return self.currentPublicKey()
            })
            .flatMap({ (publicKey) in
                return self.getSession(deviceToken: deviceToken, publicKey: publicKey)
            })
    }
    
    public func authenticate(withUsername username: String, password: String) -> Observable<Session> {
        return self.currentPublicKey()
            .flatMap { (publicKey) in
                return self.preAuthenticate(userId: username, password: password, publicKey: publicKey)
            }
            .do(onNext: { (accessToken) in
                self.accessToken = accessToken
            })
            .flatMap({ (accessToken) in
                return self.getSession()
            })
    }
    
    public func quickBalances(with quickBalanceToken: String, for accountHashes: [String]) -> Observable<[Balance]> {
        return self.currentPublicKey()
            .flatMap { (publicKey) in
                return self.preAuthenticate(quickBalanceToken: quickBalanceToken, publicKey: publicKey)
            }
            .do(onNext: { (accessToken) in
                self.accessToken = accessToken
            })
            .flatMap({ (_) -> Observable<Any> in
                let route = Route.quickBalances(accountHashes: accountHashes, showInvestmentSchemes: true)
                return self.jsonRequest(route: route)
            })
            .flatMap { (jsonData) -> Observable<[Balance]> in
                guard let balances = try? ResponseParser.parseQuickBalancesResponse(responseData: jsonData) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(balances)
            }
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
    
    public func getSession(deviceToken: String, publicKey: PublicKey) -> Observable<Session> {
        
        guard let encryptedDeviceToken = self.encryptString(string: deviceToken, withPublicKey: publicKey) else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = Route.sessions(method: Route.SessionMethod.withDeviceToken(deviceToken: encryptedDeviceToken, publicKeyId: publicKey.id))
        
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
    
    // MARK: Accounts
    
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
    
    // MARK: Devices
    
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
    
    // MARK: Pins
    
    public func setPin(pin: String) -> Observable<NewDevice> {

        let deviceDescription = self.deviceDescription
        
        guard let devicePublicKey = self.rsaUtils.getPublicKeyDER()?.base64EncodedString() else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        return self.currentPublicKey()
            .flatMap { (publicKey) -> Observable<Any> in
                
                guard let encryptedPin = self.encryptString(string: pin, withPublicKey: publicKey) else {
                    return Observable.error(ResponseParserError.UnknownResponseFormat)
                }
                
                let route = Route.setPin(pin: encryptedPin, publicKeyId: publicKey.id, deviceName: deviceDescription, devicePublicKey: devicePublicKey)
                
                return self.jsonRequest(route: route)
            }
            .flatMap { (jsonData) -> Observable<NewDevice> in
                guard let newDevice = try? ResponseParser.parseNewDeviceResponse(responseData: jsonData, rsaUtils: self.rsaUtils) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(newDevice)
            }
            .do(onNext: { [weak self] (newDevice) in
                self?.rsaUtils.deviceToken = newDevice.deviceToken
            }, onError: { [weak self] (error) in
                self?.rsaUtils.deviceToken = nil
            })
    }
    
    // MARK: Quick Balance Token
    
    public func quickBalanceToken() -> Observable<String> {
        
        guard let devicePublicKey = self.rsaUtils.getPublicKeyDER()?.base64EncodedString() else {
            return Observable.error(ResponseParserError.UnknownResponseFormat)
        }
        
        let route = Route.quickBalanceToken(devicePublicKey: devicePublicKey)

        return self.jsonRequest(route: route)
            .flatMap { (jsonData) -> Observable<String> in
                guard let quickBalanceToken = try? ResponseParser.parseQuickBalanceTokenResponse(responseData: jsonData, rsaUtils: self.rsaUtils) else {
                    return Observable.error(ServiceError.couldNotParseJSON)
                }
                return Observable.just(quickBalanceToken)
            }
    }
    
}

extension ANZService {
    
    public func encryptString(string: String, withPublicKey publicKey: PublicKey) -> String? {
        return try? SwiftyRSA.encryptString(string, publicKeyPEM: publicKey.key)
    }
    
}
