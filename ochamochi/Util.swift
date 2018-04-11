//
//  Util.swift
//  ochamochi
//
//

import Foundation
import RealmSwift

class Util {
    static let CURRENT_ACCOUNT_KEY = "currentAccount"
    static var _currentAccount : Account? = nil
    
    static func setCurrentAccount(_ account: Account) {
        UserDefaults.standard.set(account.acct, forKey: CURRENT_ACCOUNT_KEY)
        _currentAccount = nil
    }
    
    static func getCurrentAccount() -> Account? {
        if (_currentAccount != nil) {
            return _currentAccount
        }
        
        if let acct = UserDefaults.standard.value(forKey: CURRENT_ACCOUNT_KEY) as! String? {            
            let realm = try! Realm()
            let accounts = realm.objects(Account.self).filter(NSPredicate(format: "acct = %@", acct))
            if (accounts.count == 0) {
                return nil
            } else {
                return accounts[0]
            }
        } else {
            return nil
        }
    }
    
    static func getCurrentInstance() -> Instance? {
        if let  currentAccount = getCurrentAccount() {
            let realm = try! Realm()
            let instances = realm.objects(Instance.self).filter(NSPredicate(format: "url = %@", currentAccount.url))
            if (instances.count == 0) {
                return nil
            } else {
                return instances[0]
            }
        } else {
            return nil
        }
    }
}
