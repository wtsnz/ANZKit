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

class ViewController: UIViewController {

    let api = ANZAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let publicKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4tACuHIst3dC8k0hu6zKZDNB6ZN85p4LxzH1mkjT4aAW5Md/T2gToqyaSJnJbF+L81rdrkX/iOVdjdtPANbRNrkXLAvbimAzmK7Iu4G23OsoYH+d4/8W5CuJY3V0oKsf42xIdsjV7fr7dXe7hJr0La5ZWAEqAC/Qw4uSTrMnRoI7QJ/Eh3d9t3yBltByIUD2HdJSYBE3BFWHHAlpofU2aj37ZKzNkSfsoTqzYnPDwHdkFMUIk0O9h/bxWe6irlOOVZ7CCOH3YU47cUdtR/btNRz2VGuCQadBwuDLiGy3mU7kwiL0hY5+dSwrmMUysqTvxKuuXOXTRIF3oiil3GPSAwIDAQAB"
        
        let data = try? SwiftyRSA.encryptString("Test", publicKeyPEM: publicKey)
        
        self.api.publicKeys()
            .subscribe(onNext: { (response) in
                print(response)
            }, onError: { (error) in
                print(error)
            })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

