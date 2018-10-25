//
//  MakeTootViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift

class MakeTootViewController: UIViewController {
    @IBOutlet var textView: UITextView?
    @IBOutlet var tootButton: UIBarButtonItem?
    @IBOutlet var cancelButton : UIBarButtonItem?
    
    @IBOutlet var replyView: UIView?
    @IBOutlet var replyViewHeight: NSLayoutConstraint?
    
    @IBOutlet var avatarImageView: UIImageView?
    
    @IBOutlet var displayNameLabel: UILabel?
    @IBOutlet var acctLabel: UILabel?
    @IBOutlet var contentLabel: UILabel?
    
    @IBOutlet var visibilityButton : UIButton?
    @IBOutlet var visibilityText : UILabel?
    
    var inReplyToId : String?

    var visibility: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add border to TextView
        textView?.layer.borderColor = UIColor.gray.cgColor
        textView?.layer.borderWidth = 1.0
        textView?.layer.cornerRadius = 10.0
        textView?.layer.masksToBounds = true
        
        self.visibility = "public"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (inReplyToId == nil) {
            // Remove reply view components.
            replyView?.subviews.forEach { subview in
                subview.removeFromSuperview()
            }
            replyViewHeight?.constant = 0.0
            replyViewHeight?.priority = 1000
        } else {
            loadStatus(inReplyToId!)
        }
    }
    
    // load status of reply source
    func loadStatus(_ statusId:  String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(
                    statusUrl(currentAccount.url, statusId: statusId),
                    success: { response in
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let t = json as! [String:Any]
                            
                            let content  = (t["content"] as? String)?.removeHTMLTag()
                            let spoilerText = t["spoiler_text"] as? String
                            
                            let a = t["account"] as! [String:Any]
                            
                            let accountAcct = a["acct"] as? String
                            let accountDisplayName = a["display_name"] as? String
                            let accountAvatar = a["avatar"] as? String
                            
                            self.displayNameLabel?.text = accountDisplayName
                            self.acctLabel?.text = accountAcct
                            self.contentLabel?.text = content
                            
                            // add acct first unless it is reply to your toot.
                            if (accountAcct != currentAccount.acct) {
                                self.textView?.text = "@\(accountAcct!) "
                            }
                            
                            // read avatar image
                            DispatchQueue.global().async {
                                if let imageUrl = URL(string: accountAvatar!) {
                                    let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                                    let task = URLSession.shared.dataTask(with: request) {
                                        (data, response, err) in
                                        if (err == nil) {
                                            DispatchQueue.main.async {
                                                self.avatarImageView!.image = UIImage(data: data!)?.resize(size: CGSize(width:60, height:60))
                                            }
                                        }
                                    }
                                    task.resume()
                                }
                            }
                            
                            if let _ = t["emojis"] {
                                var emojis = t["emojis"] as! [Any]
                                emojis.forEach { _emoji in
                                    let tmp = _emoji as! [String:Any]
                                    let emoji = Emoji()
                                    emoji.shortcode = tmp["shortcode"] as! String
                                    emoji.url = tmp["url"] as! String
                                    emoji.staticUrl = tmp["static_url"] as! String
                                    emojis.append(emoji)
                                }
                                
                                // replace emojis
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Make toot
    @IBAction func toot(_ sender: UIBarButtonItem) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.post(
                    makeTootUrl(currentInstance.url),
                    parameters: self.tootParameters(),
                    success: {
                        response in
                        self.dismiss(animated: true, completion: nil)
                    }, failure: {
                        error in
                        print(error.localizedDescription)
                        self.dismiss(animated: true, completion: nil)
                    })
            }
        }
    }
    
    // parameters for tooting.
    private func tootParameters() -> [String:Any] {
        var parameters = ["status":(textView!.text! as Any),
                "visibility": self.visibility!]
        if (inReplyToId != nil) {
            parameters["in_reply_to_id"] = inReplyToId
        }
        
        return parameters
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func visibilityButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Visibility", message : "Select toot visibility", preferredStyle: .actionSheet)
        let emojis : DictionaryLiteral = ["public" : "globe",
                                          "unlisted": "lock-open",
                                          "private": "lock",
                                          "direct": "envelope"]
        emojis.forEach {key, value in
            let action = UIAlertAction(title: key, style: .default, handler: {
                (_ : UIAlertAction!) in
                self.visibility = key
                self.visibilityButton!.setTitle(value, for: .normal)
                self.visibilityText?.text = key
            })
            if self.visibility == key {
                action.setValue(true, forKey: "checked")
            }
            actionSheet.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (_ : UIAlertAction!) in
        })
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func makeTootUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/statuses".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func statusUrl(_ url : String, statusId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(statusId)".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
