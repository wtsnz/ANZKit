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
    
    let disposeBag = DisposeBag()
    
    lazy var service: ANZService = {
        
        let serverConfig = ServerConfig.production
        
        let deviceId = "EA06918A-844A-4BB8-B053-0827CE0E43B1"//"ad375799-7bc6-4d3a-b0a3-bed6e7ff4094" // NSUUID().uuidString
        let requestId = 5000
        
        let service = ANZService(
            serverConfig: serverConfig,
            requestId: requestId,
            apiKey: "41b4c957-56c8-4f0a-9ed6-bab90a43fcf5",
            userAgent: "goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/",
            deviceId: deviceId,
            deviceDescription: "SM-G900F",
            deviceApiVersion: "19",
            accessToken: nil,
            ibSessionId: nil
        )
        
        return service
    }()
    
    @IBOutlet weak var passcodeTextField: UITextField!
    @IBOutlet weak var smsCodeTextField: UITextField!
    
    @IBAction func touchedCreatePasscode(_ sender: Any) {
        
        guard let pin = passcodeTextField.text else {
            return
        }
  
        let utils = ANZRSAUtils()

        let (publicKey, privateKey) = utils.generateKeyPair()
        
        let keystring = utils.getPublicKeyDER(utils.tagPublic)?.base64EncodedString()

        print(keystring)

        self.service.setPin(pin: pin, deviceDescription: "iphone", devicePublicKey: keystring!)
            .subscribe(onNext: { (newDevice) in
                
                let deviceToken = utils.decryptBase64String(encryptedBase64String: newDevice.deviceToken)

                dump(newDevice)
                print(deviceToken)
                
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

        self.service.getSession(authCode: authCode)
            .do(onNext: { (session) in
                // When we get the session from the server, we must grab
                // the `ibSessionId` out and configure our service with it.
                // This is required in the Request Headers going forward.
                // Todo: Probably a good idea to move this into the Service.
                self.service.ibSessionId = session.ibSessionId
            })
            .flatMap({ (session) -> Observable<(devices: [Device], accounts: [Account])> in
                return Observable.combineLatest(self.service.getDevices(), self.service.getAccounts(), resultSelector: { (devices, accounts) -> (devices: [Device], accounts: [Account]) in
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
        
        // Generate Device Certificate Pair

        let deviceToken = ""
        let devicePin = ""
        
        self.service
            .session(withDeviceToken: deviceToken, pin: devicePin)
            .subscribe(onNext: { [weak service] (session) in
                dump(session)
            }, onError: { (error) in
                print(error)
            })
            .addDisposableTo(self.disposeBag)
        
        return;
        

        self.service
            .authenticate(withUsername: Secrets.username, password: Secrets.password)
            .subscribe(onNext: { [weak service] (session) in
                dump(session)
                }, onError: { (error) in
                    print(error)
            })
            .addDisposableTo(self.disposeBag)
        
        return;
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

