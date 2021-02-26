//
//  Client.swift
//  ochamochi
//
//

import Foundation
import RealmSwift

class Instance : Object {
    @objc dynamic var url = ""
    @objc dynamic var clientId = ""
    @objc dynamic var clientSecret = ""
}
