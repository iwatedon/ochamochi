//
//  Util.swift
//  ochamochi
//
//

import Foundation
import RealmSwift
import OAuthSwift

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
    
    
    static func loadTimeline(_ sinceId : String? = nil, maxId : String? = nil, timelineUrl: String = "", parameters: OAuthSwift.Parameters = [:],  success : @escaping (([Toot]) -> Void) = {toots in}) {
        if (sinceId != nil && maxId != nil) {
            print("error: since_id and max_id are both not nil.")
            return
        }
        var toots : [Toot] = []
        
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(
                    timelineUrl,
                    parameters: parameters,
                    success: { response in
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
                                
                                toots.append(toot)
                            }
                            
                            DispatchQueue.main.async {
                                success(toots)
                            }
                        } catch {
                            print(error)
                        }
                },
                    failure: { error in
                        print(error)
                })
            }
        }
        return
    }
}
