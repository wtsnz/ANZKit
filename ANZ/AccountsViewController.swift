//
//  AccountsViewController.swift
//  ANZ
//
//  Created by Will Townsend on 12/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import ANZKit

protocol AccountsViewControllerDelegate {
    func accountViewController(viewController: AccountsViewController, selectedAccount: Account)
}

class AccountsViewController: UITableViewController {
    
    enum State {
        case `default`
        case loading
    }
    
    let context: AppContext
    
    let state = Variable<State>(.default)
    
    let accounts = Variable<[Account]>([])
    
    var delegate: AccountsViewControllerDelegate? = nil
    
    let disposeBag = DisposeBag()
    
    init(context: AppContext) {
        self.context = context
        
        super.init(style: .grouped)
        
        self.title = "Accounts"
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.context.apiService.getAccounts()
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { [weak self] (accounts) in
                self?.accounts.value = accounts
                self?.tableView.reloadData()
            }, onError: { (error) in
                dump(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accounts.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let account = self.accounts.value[indexPath.row]
        
        cell.textLabel?.text = "\(account.nickname) - \(account.balance)"
        
        return cell

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let account = self.accounts.value[indexPath.row]
        self.delegate?.accountViewController(viewController: self, selectedAccount: account)
        
    }
}
