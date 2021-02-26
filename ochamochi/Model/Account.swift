//
//  Account.swift
//  ochamochi
//
//

import Foundation
import RealmSwift

class Account : Object {
    @objc dynamic var url = ""
    @objc dynamic var accessToken = ""
    @objc dynamic var acct = ""
}
