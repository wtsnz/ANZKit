//
//  LoginViewController.swift
//  ANZ
//
//  Created by Will Townsend on 11/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import ANZKit
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import IGListKit
import SnapKit

enum SectionType {
    case authentication
    case submit
}

enum RowType {
    case username(cell: TextInputTableViewCell)
    case password(cell: TextInputTableViewCell)
    case loginButton(cell: UITableViewCell)
}

struct Section {
    let type: SectionType
    let rows: [RowType]
}

class TextInputTableViewCell: UITableViewCell {
    
    enum State {
        case `default`
        case disabled
    }
    
    var state: State = .default {
        didSet {
            switch state {
            case .default:
                self.textField.isEnabled = true
                self.textField.textColor = UIColor.black.withAlphaComponent(1.0)
            case .disabled:
                self.textField.isEnabled = false
                self.textField.textColor = UIColor.black.withAlphaComponent(0.3)
            }
        }
    }
    
    static let ReuseIdentifier = "TextInputTableViewCellReuseIdentifier"
    
    lazy var textField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.textField)
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        
        self.textField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
        self.textField.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.textField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15).isActive = true
        self.textField.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ButtonTableViewCell: UITableViewCell {
    
    enum State {
        case `default`
        case loading
        case disabled
    }
    
    var state: State = .default {
        didSet {
            switch state {
            case .default:
                self.titleLabel.isHidden = false
                self.titleLabel.textColor = UIColor.black.withAlphaComponent(1.0)
                self.activityIndicator.isHidden = true
            case .loading:
                self.titleLabel.isHidden = true
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            case .disabled:
                self.titleLabel.isHidden = false
                self.titleLabel.textColor = UIColor.black.withAlphaComponent(0.3)
                self.activityIndicator.isHidden = true
            }
        }
    }
    
    static let ReuseIdentifier = "ButtonTableViewCellReuseIdentifier"
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        return titleLabel
    }()
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        return activityIndicator
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
        self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15).isActive = true
        self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        
        self.contentView.addSubview(self.activityIndicator)
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        self.state = .default
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class AuthenticationViewController: UIViewController {
    
    let context: AppContext
    
    init(context: AppContext) {
        self.context = context
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Sign in"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let layout = UICollectionViewFlowLayout()
        let collectionView = IGListCollectionView(frame: .zero, collectionViewLayout: layout)
        
        self.view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        let updater = IGListAdapterUpdater()
        let adapter = IGListAdapter(updater: updater, viewController: self, workingRangeSize: 0)
        adapter.collectionView = collectionView
        
        
    }
    
}

class LoginViewControllerViewModel {
    
    let username: Observable<String>
    let password: Observable<String>
    
    let signupEnabled: Observable<Bool>
    
    let signedIn: Observable<Session>
    
    init(input: (
            username: Observable<String>,
            password: Observable<String>,
            loginTaps: Observable<Void>
        ),
         context: AppContext
    ) {
    
        self.username = input.username.shareReplay(1)
        self.password = input.password.shareReplay(1)
        
        signupEnabled = Observable.combineLatest(self.username, self.password, resultSelector: { (username, password) -> Bool in
            
            guard username.characters.count > 4 else {
                return false
            }
            
            guard password.characters.count > 4 else {
                return false
            }
            
            return true
        })
        .distinctUntilChanged()
        .shareReplay(1)
        
        
        let usernameAndPassword = Observable.combineLatest(self.username, self.password) { ($0, $1) }
        
        self.signedIn = input.loginTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest({ (username, password) in
                context.apiService.authenticate(withUsername: username, password: password)
                    .observeOn(MainScheduler.instance)
            })
//            .shareReplay(1)
        
    }
    
}

protocol LoginViewControllerDelegate {
    func loginViewController(viewController: LoginViewController, didRequestLoginWith username: String, password: String)
}

class LoginViewController: UITableViewController {
    
    enum State {
        case `default`
        case loading
    }
    
    let context: AppContext
    
    let username = Variable<String?>(nil)
    let password = Variable<String?>(nil)
    
    let valid = BehaviorSubject<Bool>(value: false)
    
    let state = Variable<State>(.default)
    
    var delegate: LoginViewControllerDelegate? = nil
    
    var sections = [Section]()
    
    let disposeBag = DisposeBag()
    
    lazy var usernameTableViewCell: TextInputTableViewCell = {
        let usernameTableViewCell = TextInputTableViewCell()
        usernameTableViewCell.selectionStyle = .none
        usernameTableViewCell.textField.placeholder = "Customer Id"
        usernameTableViewCell.textField.rx.text <-> self.username
        return usernameTableViewCell
    }()
    
    lazy var passwordTableViewCell: TextInputTableViewCell = {
        let passwordTableViewCell = TextInputTableViewCell()
        passwordTableViewCell.selectionStyle = .none
        passwordTableViewCell.textField.placeholder = "Password"
        passwordTableViewCell.textField.isSecureTextEntry = true
        passwordTableViewCell.textField.rx.text <-> self.password
        return passwordTableViewCell
    }()
    
    lazy var loginButtonTableViewCell: ButtonTableViewCell = {
        let loginButtonTableViewCell = ButtonTableViewCell()
        loginButtonTableViewCell.titleLabel.text = "Log in"
        return loginButtonTableViewCell
    }()
    
    init(context: AppContext) {
        self.context = context
        
        super.init(style: .grouped)
        
        let sections = [
            Section(type: .authentication, rows: [
                .username(cell: self.usernameTableViewCell),
                .password(cell: self.passwordTableViewCell)
                ]),
            Section(type: .submit, rows: [
                .loginButton(cell: self.loginButtonTableViewCell)
                ])
        ]
        
        self.sections = sections
        
        self.title = "Sign in"
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: TextInputTableViewCell.ReuseIdentifier)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        Observable
            .combineLatest(self.username.asObservable(), self.password.asObservable()) { (username, password) in
                return (username, password)
            }
            .map { (username, password) -> Bool in
                
                guard let username = username, username.characters.count > 4 else {
                    return false
                }
                
                guard let password = password, password.characters.count > 4 else {
                    return false
                }
                
                return true
            }
            .bindTo(self.valid)
        
        
        Observable
            .combineLatest(self.state.asObservable(), self.valid.asObservable()) { (state, valid) in
                return (state, valid)
            }
            .subscribe(onNext: { (state, valid) in
                
                switch state {
                case .default:
                    
                    if valid {
                        self.loginButtonTableViewCell.state = .default
                    } else {
                        self.loginButtonTableViewCell.state = .disabled
                    }
                    
                    self.usernameTableViewCell.state = .default
                    self.passwordTableViewCell.state = .default
                case .loading:
                    self.loginButtonTableViewCell.state = .loading
                    self.usernameTableViewCell.state = .disabled
                    self.passwordTableViewCell.state = .disabled
                }
                
            })
        .addDisposableTo(self.disposeBag)
        
        self.username.asDriver().drive(onNext: { (username) in
            print("username: \(username)")
        })

        
    }
    
    func login() {
        
        let valid = try? self.valid.value()
        
        guard valid == true else {
            return
        }
        
        guard let username = self.username.value else {
            return
        }
        
        guard let password = self.password.value else {
            return
        }
        
        self.delegate?.loginViewController(viewController: self, didRequestLoginWith: username, password: password)
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
        case .username(let cell):
            return cell
        case .password(let cell):
            return cell
        case .loginButton(let cell):
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch self.sections[indexPath.section].rows[indexPath.row] {
        case .loginButton:
            self.login()
        default:
            break
        }
        
    }
    
    
}
