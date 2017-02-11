//
//  LoginViewController.swift
//  ANZ
//
//  Created by Will Townsend on 11/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import UIKit

enum SectionType {
    case authentication
    case submit
}

enum RowType {
    case username
    case password
    case loginButton
}

struct Section {
    let type: SectionType
    let rows: [RowType]
}

class LoginViewController: UITableViewController {
    
    let context: AppContext
    
    var sections: [Section]
    
    init(context: AppContext) {
        self.context = context
        
        let sections = [
            Section(type: .authentication, rows: [
                .username,
                .password
            ]),
            Section(type: .submit, rows: [
                .loginButton
            ])
        ]
        
        self.sections = sections
        
        super.init(style: .grouped)
        
        self.title = "Sign in"
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch self.sections[indexPath.section].rows[indexPath.row] {
        case .username:
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            return cell
            
        case .password:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            return cell
            
        case .loginButton:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Login"
            return cell

        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
