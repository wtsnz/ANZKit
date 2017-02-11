//
//  ViewController.swift
//  ANZ
//
//  Created by Will Townsend on 8/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import UIKit
import ANZKit
import Alamofire
import SwiftyRSA
import RxSwift

class ViewController: UIViewController {
    
    // Make sure
    var context: AppContext! = nil
    
    let disposeBag = DisposeBag()
    
    var accountHashes = [String]()
    
    
    @IBAction func touchedGetQuickBalances(_ sender: Any) {
        
        let quickBalanceToken = self.quickBalanceToken.text ?? ""
        
        self.context.apiService.quickBalances(with: quickBalanceToken, for: accountHashes)
            .subscribe(onNext: { (balances) in
                dump(balances)
            }, onError: { (error) in
                print(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }
    
    @IBOutlet weak var quickBalanceToken: UILabel!
    
    @IBOutlet weak var passcodeTextField: UITextField!
    @IBOutlet weak var smsCodeTextField: UITextField!
    
    @IBAction func touchedCreatePasscode(_ sender: Any) {
        
        guard let pin = passcodeTextField.text else {
            return
        }

        self.context.apiService.setPin(pin: pin)
            .subscribe(onNext: { (newDevice) in
                
                dump(newDevice)

            }, onError: { (error) in
                print(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }
    
    @IBAction func tappedAuth(_ sender: Any) {
        
        guard let authCode = smsCodeTextField.text else {
            return
        }
        
        print("code: \(authCode)")

        self.context.apiService.getSession(authCode: authCode)
            .flatMap({ (session) -> Observable<(devices: [Device], accounts: [Account])> in
                return Observable.combineLatest(self.context.apiService.getDevices(), self.context.apiService.getAccounts(), resultSelector: { (devices, accounts) -> (devices: [Device], accounts: [Account]) in
                    return (devices: devices, accounts: accounts)
                })
            })
            .subscribe(onNext: { (devices, accounts) in
                
                dump(devices)
                dump(accounts)
                
            }, onError: { (error) in
                print(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Save the sessionID too?
    
//        self.context.apiService.ibSessionId = "e81c898a-2e47-48c8-b012-93ba3c1b9172"
        
        if let deviceToken = self.context.apiService.deviceToken {
            
            let devicePin = Secrets.passcode
            
            self.context.apiService
                .session(withDeviceToken: deviceToken, pin: devicePin)
                .flatMap({ (session) -> Observable<(devices: [Device], accounts: [Account])> in
                    return Observable.combineLatest(self.context.apiService.getDevices(), self.context.apiService.getAccounts(), resultSelector: { (devices, accounts) -> (devices: [Device], accounts: [Account]) in
                        return (devices: devices, accounts: accounts)
                    })
                })
                .subscribe(onNext: { (devices, accounts) in
                    
                    self.accountHashes = accounts.map({ (account) -> String in
                        return account.hashedAccountNumber
                    })
                    
                    dump(devices)
                    
                    dump(accounts)
                    
                    self.context.apiService.quickBalanceToken()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (quickBalanceToken) in
                            
                            self.quickBalanceToken.text = quickBalanceToken
                            
                        }, onError: { (error) in
                            print(error)
                        })
                        .addDisposableTo(self.disposeBag)
                    
                    
                }, onError: { (error) in
                    print(error)
                })
                .addDisposableTo(self.disposeBag)
            
        } else {
            
            self.context.apiService
                .authenticate(withUsername: Secrets.username, password: Secrets.password)
                .subscribe(onNext: { [weak self] (session) in
                    dump(session)
                    }, onError: { (error) in
                        print(error)
                })
                .addDisposableTo(self.disposeBag)
        }
        
    }
}

