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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let serverConfig = ServerConfig.production
        
        let service = ANZService(
            serverConfig: serverConfig,
            apiKey: "41b4c957-56c8-4f0a-9ed6-bab90a43fcf5",
            userAgent: "goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/",
            deviceDescription: "SM-G900F",
            deviceApiVersion: "19",
            accessToken: nil
        )
        
        service
            .authenticate(withUsername: Secrets.username, password: Secrets.password)
            .subscribe(onNext: { [weak service] (session) in
                //service?.accessToken = accessToken
                dump(session)
            }, onError: { (error) in
                print(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

