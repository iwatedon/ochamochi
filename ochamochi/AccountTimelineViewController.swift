//
//  AccountTimelineViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift

class AccountTimelineViewController: TimelineViewController {
    @IBOutlet var avatarImageView: UIImageView?
    @IBOutlet var displayNameLabel: UILabel?
    @IBOutlet var acctLabel: UILabel?
    @IBOutlet var noteTextView: UITextView?
    
    @IBOutlet var headerView : UIView?
    
    var accountId: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadAccount()
    }
    
    override func getTabBarIconName() -> String {
        return ""
    }
    
    override func getTimelineUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/accounts/\(self.accountId!)/statuses".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    override func getParameters(since_id: String?, max_id: String?) -> OAuthSwift.Parameters {
        var result : [String:Any] = [:]
        if let _ = since_id {
            result["since_id"] = since_id! as Any
        }
        if let _ = max_id {
            result["max_id"] = max_id! as Any
        }
        return result
    }
    
    private func accountUrl(_ url: String, accountId: String) -> String {
        return "https://\(url)/api/v1/accounts/\(accountId)".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func loadAccount() {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(
                    accountUrl(currentAccount.url, accountId: accountId!),
                    success: { response in
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let a = json as! [String:Any]
                            
                            let accountAcct = a["acct"] as? String
                            let accountDisplayName = a["display_name"] as? String
                            let accountAvatar = a["avatar"] as? String
                            let accountNote = a["note"] as? String
                            
                            self.displayNameLabel?.text = accountDisplayName
                            self.acctLabel?.text = "@\(accountAcct!)"
                            
                            self.noteTextView?.text = accountNote?.removeHTMLTag()
                            
                            // resize headerView according to auto-layout.
                            self.headerView?.setNeedsLayout()
                            self.headerView?.layoutIfNeeded()
                            let size = self.headerView!.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                            self.headerView?.frame = CGRect(x:0, y:0, width: size.width, height: size.height)
                            self.tableView.tableHeaderView = self.headerView
                            
                        
                            self.title = accountDisplayName
                            
                            // read avatar image
                            DispatchQueue.global().async {
                                if let imageUrl = URL(string: accountAvatar!) {
                                    let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                                    let task = URLSession.shared.dataTask(with: request) {
                                        (data, response, err) in
                                        if (err == nil) {
                                            DispatchQueue.main.async {
                                                self.avatarImageView!.image = UIImage(data: data!)?.resize(size: CGSize(width:90, height:90))
                                            }
                                        }
                                    }
                                    task.resume()
                                }
                            }
                        } catch {
                            print(error)
                        }
                }, failure: {
                    error in
                    print(error.localizedDescription)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
}
