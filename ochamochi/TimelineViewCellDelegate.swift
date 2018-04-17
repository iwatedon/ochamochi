//
//  TimelineViewCellDelegate.swift
//  ochamochi
//
//

import Foundation
import UIKit
import OAuthSwift

protocol TimelineViewCellDelegate {
    func reply(_ tootId: String)
    func fav(_ tootId: String)
    func unfav(_ tootId: String)
    func reblog(_ tootId: String)
    func unreblog(_ tootId: String)
    func confirmDelete(_ tootId: String)
    
    func accountDetail(_ accountId: String)
}

extension TimelineViewCellDelegate where Self: TimelineViewController {
    func reply(_ tootId: String) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "MakeTootView") {
            ((controller as! UINavigationController).viewControllers.first as! MakeTootViewController).inReplyToId = tootId
            present(controller, animated: true, completion: nil)
        }
    }
    
    func fav(_ tootId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            favCommon(tootId, url: favoriteUrl(currentAccount.url, tootId: tootId))
            for (index, toot) in toots.enumerated() {
                if toot.id == tootId {
                    toot.favourited = true
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
                    }
                }
            }
        }
    }
    
    func unfav(_ tootId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            favCommon(tootId, url: unfavoriteUrl(currentAccount.url, tootId: tootId))
            for (index, toot) in toots.enumerated() {
                if toot.id == tootId {
                    toot.favourited = false
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
                    }
                }
            }
        }
    }
    
    func reblog(_ tootId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            reblogCommon(tootId, url: reblogUrl(currentAccount.url, tootId: tootId))
            for (index, toot) in toots.enumerated() {
                if toot.id == tootId {
                    toot.reblogged = true
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
                    }
                }
            }
        }
    }
    
    func unreblog(_ tootId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            reblogCommon(tootId, url: unreblogUrl(currentAccount.url, tootId: tootId))
            for (index, toot) in toots.enumerated() {
                if toot.id == tootId {
                    toot.reblogged = false
                    DispatchQueue.main.async {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.none)
                    }
                }
            }
        }
    }
    
    private func favCommon(_ tootId: String, url: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.post(
                    url,
                    success: { response in
                        do {
                            // set acct to Account and save
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let status = json as! [String:Any]
                        } catch {
                            print(error)
                        }
                },
                    failure: { error in
                        print(error)
                })
            }
        }
    }
    
    private func reblogCommon(_ tootId: String, url: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.post(
                    url,
                    success: { response in
                        do {
                            // set acct to Account and save
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let status = json as! [String:Any]
                        } catch {
                            print(error)
                        }
                },
                    failure: { error in
                        print(error)
                })
            }
        }
    }
    
    func accountDetail(_ accountId: String) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "AccountTimelineView") {
            (controller as! AccountTimelineViewController).accountId = accountId
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func delete(_ tootId: String) {
        confirmDelete(tootId)
        // deleteImpl(tootId)
    }
    
    func confirmDelete(_ tootId: String) {
        let alert: UIAlertController = UIAlertController(title: "Delete toot", message: "Do you really want to delete toot?", preferredStyle:  UIAlertControllerStyle.alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.deleteImpl(tootId)
        })
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteImpl(_ tootId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.delete(
                    self.deleteTootUrl(currentAccount.url, tootId: tootId),
                    success: { response in
                        for (index, toot) in self.toots.enumerated() {
                            if toot.id == tootId {
                                self.toots.remove(at: index)
                                break
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                },
                    failure: { error in
                        print(error)
                })
            }
        }
    }
    
    private func favoriteUrl(_ url : String, tootId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/favourite".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func unfavoriteUrl(_ url : String, tootId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/unfavourite".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func reblogUrl(_ url : String, tootId: String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/reblog".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func unreblogUrl(_ url : String, tootId: String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/unreblog".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func deleteTootUrl(_ url: String, tootId: String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
}
