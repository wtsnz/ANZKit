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

