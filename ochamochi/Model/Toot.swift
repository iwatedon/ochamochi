//
//  Toot.swift
//  ochamochi
//
//

import Foundation

// Non-Realm
class Toot {
    var id : String? = ""
    var uri : String? = ""
    var url : String? = ""
    var content : String? = ""
    var spoilerText : String? = ""
    var createdAt: Date? = nil
    
    var accountId : String? = ""
    var accountAcct : String? = ""
    var accountDisplayName: String? = ""
    var accountAvatar : String? = ""
    
    var boosted: Bool = false // reblogged by me or other accounts
    var boostAccontDisplayName: String? = ""
    
    var favourited: Bool? = nil
    var reblogged: Bool? = nil // reblogged by me
    var sensitive: Bool? = nil
    
    var emojis: [Emoji] = []
    var mentions: [Mention] = []
    var attachments: [Attachment] = []
    
    var visibility: String? = nil
}
