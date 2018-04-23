//
//  MastodonNotification.swift
//  ochamochi
//
//

import Foundation

class MastodonNotification {
    var id : String? = nil
    var type: String? = nil
    var createdAt: Date? = nil

    var accountId: String? = nil
    var accountAcct: String? = nil
    var accountDisplayName: String? = nil
    var accountAvatar: String? = nil
    
    var tootId : String? = nil
    var tootUri : String? = nil
    var tootUrl : String? = nil
    var tootContent : String? = nil
    var tootSpoilerText : String? = nil
    var tootCreatedAt: Date? = nil
    
    var tootAccountAvatar: String? = nil
}
