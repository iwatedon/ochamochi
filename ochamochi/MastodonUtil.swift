//
//  Util.swift
//  ochamochi
//
//

import Foundation
import RealmSwift
import OAuthSwift
import WebLinking

class MastodonUtil {
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
    
    static func loadTimeline(_ sinceId : String? = nil, maxId : String? = nil, timelineUrl: String = "", parameters: OAuthSwift.Parameters = [:],  success : @escaping (([Toot], String?) -> Void) = {toots, maxId in}, useWebLinking: Bool = false) {
        if (sinceId != nil && maxId != nil) {
            print("error: since_id and max_id are both not nil.")
            return
        }
        var toots : [Toot] = []
        
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(timelineUrl, parameters: parameters) { result in
                    switch result {
                    case .success(let response):
                        do {
                            // set acct to Account and save
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let _toots = json as! [Any]
                            _toots.forEach { _toot in
                                var t = _toot as! [String:Any]
                                var boosted = false
                                var boost_account_display_name : String? = nil
                                
                                let toot = Toot()
                                toot.id = t["id"] as? String // use original ID regardless whether the toot is boosted one or not.

                                // Boost
                                if !(t["reblog"] is NSNull) {
                                    boosted = true
                                    boost_account_display_name = (t["account"] as! [String:Any])["display_name"] as? String
                                    
                                    t = t["reblog"] as! [String:Any]
                                }
                                
                                toot.url = t["url"] as? String
                                toot.uri = t["uri"] as? String
                                toot.content = (t["content"] as? String)?.removeHTMLTag()
                                toot.spoilerText = t["spoiler_text"] as? String
                                toot.createdAt = DateFormatter().date(fromSwapiString: (t["created_at"] as? String)!)
                                
                                let a = t["account"] as! [String:Any]
                                toot.accountId = a["id"] as? String
                                toot.accountAcct = a["acct"] as? String
                                toot.accountDisplayName = a["display_name"] as? String
                                toot.accountAvatar = a["avatar"] as? String
                                
                                if (boosted) {
                                    toot.boosted = boosted
                                    toot.boostAccontDisplayName = boost_account_display_name
                                }
                                
                                toot.favourited = t["favourited"] as? Bool
                                toot.reblogged = t["reblogged"] as? Bool
                                toot.sensitive = t["sensitive"] as? Bool
                                
                                toot.visibility = t["visibility"] as? String
                                
                                if let _ = t["emojis"] {
                                    let emojis = t["emojis"] as! [Any]
                                    emojis.forEach { _emoji in
                                        let tmp = _emoji as! [String:Any]
                                        let emoji = Emoji()
                                        emoji.shortcode = tmp["shortcode"] as! String
                                        emoji.url = tmp["url"] as! String
                                        emoji.staticUrl = tmp["static_url"] as! String
                                        toot.emojis.append(emoji)
                                    }
                                }
                                
                                if let _ = t["mentions"] {
                                    let mentions = t["mentions"] as! [Any]
                                    mentions.forEach { _mention in
                                        let tmp = _mention as! [String:Any]
                                        let mention = Mention()
                                        mention.url = tmp["url"] as! String
                                        mention.username = tmp["username"] as! String
                                        mention.acct = tmp["acct"] as! String
                                        mention.id = tmp["id"] as! String
                                        toot.mentions.append(mention)
                                    }
                                }
                                
                                if let _ = t["media_attachments"] {
                                    let media_attachments = t["media_attachments"] as! [Any]
                                    media_attachments.forEach { _attachment in
                                        let tmp = _attachment as! [String:Any]
                                        let attachment = Attachment()
                                        attachment.id = tmp["id"] as! String?
                                        attachment.type = tmp["type"] as! String?
                                        attachment.url = tmp["url"] as! String?
                                        attachment.previewUrl = tmp["preview_url"] as! String?
                                        
                                        if !(tmp["remote_url"] is NSNull) {
                                            attachment.remoteUrl = tmp["remote_url"] as! String?
                                        }
                                        
                                        if !(tmp["text_url"] is NSNull) {
                                            attachment.textUrl = tmp["text_url"] as! String?
                                        }
                                        // attachment.meta = tmp["meta"] as! String?
                                        if !(tmp["description"] is NSNull) {
                                            attachment.description = tmp["description"] as! String?
                                        }
                                        toot.attachments.append(attachment)
                                    }
                                }
                                
                                toots.append(toot)
                            }
                            
                            var maxId : String? = nil
                            if (useWebLinking) {
                                if let link = response.response.findLink(relation: "next") {
                                    maxId = String(link.uri.split(separator: "?")[1].split(separator: "=")[1])
                                }
                            } else if (toots.count > 0) {
                                maxId = toots.last?.id
                            }
                            
                            DispatchQueue.main.async {
                                success(toots, maxId)
                            }
                        } catch {
                            print(error)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        return
    }
    
    static func loadNotification(_ sinceId : String? = nil, maxId : String? = nil, timelineUrl : String = "", parameters: OAuthSwift.Parameters = [:],  success : @escaping (([MastodonNotification], String?) -> Void) = {notifications, maxId in}) {
        var notifications : [MastodonNotification] = []
        
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(timelineUrl, parameters: parameters) { result in
                    switch result {
                    case .success(let response):
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let _notifications = json as! [Any]
                            _notifications.forEach { _notification in
                                var notification = MastodonNotification()
                                var n = _notification as! [String:Any]
                                
                                notification.id = n["id"] as? String
                                notification.type = n["type"] as? String
                                notification.createdAt = DateFormatter().date(fromSwapiString: (n["created_at"] as? String)!)
                                
                                var a = n["account"] as! [String:Any]
                                notification.accountId = a["id"] as? String
                                notification.accountAcct = a["acct"] as? String
                                notification.accountDisplayName = a["display_name"] as? String
                                notification.accountAvatar = a["avatar"] as? String
                                
                                if (n["status"] != nil) {
                                    var t = n["status"] as! [String:Any]
                                    notification.tootId = t["id"] as? String
                                    notification.tootUri = t["uri"] as? String
                                    notification.tootUrl = t["url"] as? String
                                    notification.tootContent = (t["content"] as? String)?.removeHTMLTag()
                                    notification.tootSpoilerText = t["spoiler_text"] as? String
                                    
                                    var me = t["account"] as! [String:Any]
                                    
                                    notification.tootAccountAvatar = me["avatar"] as? String
                                }
                                
                                notifications.append(notification)
                            }
                            var maxId : String? = nil
                            if (notifications.count > 0) {
                                maxId = notifications[0].id
                            }
                            
                            DispatchQueue.main.async {
                                success(notifications, maxId)
                            }
                        } catch {
                            print(error)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        
        return
    }
    
    static func normalizeAcct(_ acct: String) -> String {
        if (acct.contains("@")) {
            return acct
        } else {
            return acct + "@" + MastodonUtil.getCurrentInstance()!.url
        }
    }
}
