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

public class ANZAPI {
    
    let manager = Alamofire.SessionManager()
    
    public init() {
        
    }
    
    public func publicKeys() -> Observable<DataResponse<Any>> {
        
        return Observable.create({ [unowned self] observer in
            
            self.manager
                .request(AuthenticationAPIRouter.publicKeys)
                .validate()
                .responseJSON { response in
                    observer.on(.next(response))
                    observer.on(.completed)
            }
            
            return Disposables.create()
            
        })

    }
    
}
