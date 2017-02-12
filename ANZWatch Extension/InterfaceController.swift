//
//  InterfaceController.swift
//  ANZWatch Extension
//
//  Created by Will Townsend on 7/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class AccountRowController: NSObject {

    static let RowType = "Account"
    
    @IBOutlet var accountNameLabel: WKInterfaceLabel!
    @IBOutlet var accountBalanceLabel: WKInterfaceLabel!
}

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var accountTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let delegate = WKExtension.shared().delegate as! ExtensionDelegate

        self.loadAccounts()
    }
    
    func loadAccounts() {
        
        let delegate = WKExtension.shared().delegate as! ExtensionDelegate
        let accounts = delegate.balances
        
        let rowCount = accounts.count
        self.accountTable.setNumberOfRows(rowCount, withRowType: AccountRowController.RowType)
        
        for i in 0 ..< rowCount {
            
            let row = self.accountTable.rowController(at: i) as! AccountRowController
            
            let accountName = accounts[i]["nickname"] as? String
            let accountBalance = accounts[i]["balance"] as? String
            
            row.accountBalanceLabel.setText(accountBalance ?? "??")
            row.accountNameLabel.setText(accountName ?? "Unknown")
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        print("selected: rowIndex:\(rowIndex)")
        
        let delegate = WKExtension.shared().delegate as! ExtensionDelegate
        delegate.requestBalances { (_) in
            self.loadAccounts()
        }
        
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
