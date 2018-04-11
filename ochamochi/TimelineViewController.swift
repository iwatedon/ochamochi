//
//  TimelineViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift
import RealmSwift
import DateToolsSwift
import Floaty

class TimelineViewController: UITableViewController, TimelineViewCellDelegate {
    
    var toots : [Toot] = []
    
    var isLoading = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.tabBarItem.image = UIImage.fontAwesomeImage(name: self.getTabBarIconName(), textColor: UIColor.black, size: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate)
        self.tabBarItem.selectedImage = UIImage.fontAwesomeImage(name: self.getTabBarIconName(), textColor: UIColor.buttonDefault, size: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "TimelineViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
    
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TimelineViewController.onRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    func onRefresh(_ sender: UIRefreshControl) {
        sender.beginRefreshing()
        
        /* var sinceId: String? = nil
        if (toots.count > 0) {
            sinceId = toots[0].id
        }
        loadTimeline(sinceId) */
        
        clearTimeline()
        
        loadTimeline()
        
        sender.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Setting title view
        updateTitleView()
        
        setupRightBarButtonItems()
        
        if (toots.count == 0) {
            loadTimeline()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toots.count
    }
    
    /* override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    } */
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TimelineViewCell
        
        cell.contentLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        
        let toot = toots[indexPath.row]
        
        cell.delegate = self
        cell.tootId = toot.id
        
        var contentText : String = ""
        if let spoiler_text = toot.spoilerText {
            if (spoiler_text != "") {
                // CW
                contentText = spoiler_text + "\n\n" + toot.content!
            } else {
                contentText = toot.content!
            }
        } else {
            contentText = toot.content!
        }
        var contentAttributedText = NSMutableAttributedString(string: contentText, attributes:[:])
        cell.contentLabel?.attributedText = contentAttributedText
        cell.contentLabel?.sizeToFit()
        
        // replace Emojis
        toot.emojis.forEach { emoji in
            let request = URLRequest(url: URL(string: emoji.staticUrl!)!,
                                     cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 24 * 60 * 60)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
            session.dataTask(with: request, completionHandler: { (data, response, error) in
                if (error == nil) {
                    let image = UIImage(data: data!)
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    attachment.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
                    
                    cell.contentLabel?.attributedText = cell.contentLabel?.attributedText?.replaceEmoji(pattern: ":\(emoji.shortcode!):", replacement: NSAttributedString(attachment: attachment))
                    cell.contentLabel?.sizeToFit()
                } else {
                    print(error)
                }
            }).resume()
        }
        
        cell.displayNameLabel?.text = toot.accountDisplayName!
        cell.acctLabel?.text = toot.accountAcct!
        cell.createdAtLabel?.text = toot.createdAt?.shortTimeAgoSinceNow
        
        if (toot.boosted) {
            cell.boostLabel?.isHidden = false
            cell.boostLabel?.text = "\(toot.boostAccontDisplayName!) boosted"
            cell.boostLabelHeight?.constant = 15
        } else {
            cell.boostLabel?.isHidden = true
            cell.boostLabelHeight?.constant = 0
        }
        
        cell.replyButton?.setTitleColor(UIColor.gray, for: .normal)
        cell.replyButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 16)
        
        if (toot.visibility == "private") {
            cell.boostButton?.setTitle("lock", for: .normal)
            cell.boostButton?.isEnabled = false
        } else if (toot.visibility == "direct") {
            cell.boostButton?.setTitle("envelope", for: .normal)
            cell.boostButton?.isEnabled = false
        } else if let reblogged = toot.reblogged {
            cell.boostButton?.setTitle("retweet", for: .normal)
            cell.boostButton?.isEnabled = true
            cell.boosted = reblogged
            cell.boostButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 16)
            if (reblogged) {
                cell.boostButton?.setTitleColor(UIColor.buttonDefault, for: .normal)
            } else {
                cell.boostButton?.setTitleColor(UIColor.gray, for: .normal)
            }
        }
        
        if let favourited = toot.favourited {
            cell.favourited = favourited
            if (favourited) {
                cell.favButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 16)
                cell.favButton?.setTitleColor(UIColor.buttonDefault, for: .normal)
            } else {
                cell.favButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeRegular", size: 12)
                cell.favButton?.setTitleColor(UIColor.gray, for: .normal)
            }
        }
        
        // read avatar image
        DispatchQueue.global().async {
            if let imageUrl = URL(string: toot.accountAvatar!) {
                let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, err) in
                    if (err == nil) {
                        DispatchQueue.main.async {
                            cell.avatarImageView!.image = UIImage(data: data!)?.resize(size: CGSize(width:60, height:60))
                            cell.layoutSubviews()
                        }
                    }
                }
                task.resume()
            }
        }
        
        return cell
    }
    
    var lock = NSLock()
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.toots.count > 0) {
            self.lock.lock()
            defer { self.lock.unlock() }
            if (isLoading == true) {
                return
            } else if tableView.contentOffset.y + tableView.frame.size.height > tableView.contentSize.height && tableView.isDragging {
                isLoading = true
                print("API呼ばれる")
                loadTimeline(nil, maxId: toots.last!.id)
            }
        }
    }
    
    func clearTimeline() {
        toots = []
        self.tableView.reloadData()
    }
    
    private func loadTimeline(_ sinceId : String? = nil, maxId : String? = nil) {
        if (sinceId != nil && maxId != nil) {
            print("error: since_id and max_id are both not nil.")
            return
        }
        
        if let currentAccount = Util.getCurrentAccount() {
            if let currentInstance = Util.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(
                    self.getTimelineUrl(currentAccount.url),
                    parameters: self.getParameters(since_id: sinceId, max_id: maxId),
                    success: { response in
                        do {
                            // set acct to Account and save
                            let dataString = response.string
                            var tmp : [Toot] = []
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let _toots = json as! [Any]
                            _toots.forEach { _toot in
                                var t = _toot as! [String:Any]
                                var boosted = false
                                var boost_account_display_name : String? = nil
                                
                                // Boost
                                if !(t["reblog"] is NSNull) {
                                    boosted = true
                                    boost_account_display_name = (t["account"] as! [String:Any])["display_name"] as? String
                                    
                                    t = t["reblog"] as! [String:Any]
                                    
                                }
                                
                                let toot = Toot()
                                toot.id = t["id"] as? String
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
                                
                                tmp.append(toot)
                            }
                            
                            if (maxId != nil) {
                                self.toots = self.toots + tmp
                            } else {
                                self.toots = tmp + self.toots
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                if (maxId != nil) {
                                  self.isLoading = false
                                }
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
    }
    
    func getTabBarIconName() -> String {
        return ""
    }
    
    func getTimelineUrl(_ url : String) -> String {
        return ""
    }
    
    func favoriteUrl(_ url : String, tootId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/favourite".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func unfavoriteUrl(_ url : String, tootId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/unfavourite".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func reblogUrl(_ url : String, tootId: String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/reblog".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func unreblogUrl(_ url : String, tootId: String) -> String {
        return "https://\(url)/api/v1/statuses/\(tootId)/unreblog".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func getParameters(since_id: String?, max_id: String?) -> OAuthSwift.Parameters {
        var result : [String:Any] = [:]
        if let _ = since_id {
            result["since_id"] = since_id! as Any
        }
        if let _ = max_id {
            result["max_id"] = max_id! as Any
        }
        return result
    }
    
    func logout() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(Util.getCurrentAccount()!)
            }
            let accounts = realm.objects(Account.self)
            if (accounts.count > 0) {
                // change current account to first
                Util.setCurrentAccount(accounts[0])
                
                // invalidate all timelines
                if let controllers = (self.parent as! UITabBarController).viewControllers {
                    controllers.forEach { controller in
                        let timeline = controller as! TimelineViewController
                        timeline.clearTimeline()
                        timeline.viewWillAppear(false)
                    }
                }
            } else {
                // go to new instance view
                self.parent?.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        } catch {
            print(error)
        }
    }
    
    @objc func openSelectAccountView(_ sender: UILabel) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "SelectAccountView") {
            present(controller, animated: true, completion: nil)
        }
    }
    
    func reply(_ tootId: String) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "MakeTootView") {
            ((controller as! UINavigationController).viewControllers.first as! MakeTootViewController).inReplyToId = tootId
            present(controller, animated: true, completion: nil)
        }
    }
    
    func fav(_ tootId: String) {
        if let currentAccount = Util.getCurrentAccount() {
            favCommon(tootId, url: favoriteUrl(currentAccount.url, tootId: tootId))
            toots.forEach { toot in
                if toot.id == tootId {
                    toot.favourited = true
                }
            }
        }
    }
    
    func unfav(_ tootId: String) {
        if let currentAccount = Util.getCurrentAccount() {
            favCommon(tootId, url: unfavoriteUrl(currentAccount.url, tootId: tootId))
            toots.forEach { toot in
                if toot.id == tootId {
                    toot.favourited = false
                }
            }
        }
    }
    
    func reblog(_ tootId: String) {
        if let currentAccount = Util.getCurrentAccount() {
            reblogCommon(tootId, url: reblogUrl(currentAccount.url, tootId: tootId))
            toots.forEach { toot in
                if toot.id == tootId {
                    toot.reblogged = true
                }
            }
        }
    }
    
    func unreblog(_ tootId: String) {
        if let currentAccount = Util.getCurrentAccount() {
            reblogCommon(tootId, url: unreblogUrl(currentAccount.url, tootId: tootId))
            toots.forEach { toot in
                if toot.id == tootId {
                    toot.reblogged = false
                }
            }
        }
    }
    
    private func favCommon(_ tootId: String, url: String) {
        if let currentAccount = Util.getCurrentAccount() {
            if let currentInstance = Util.getCurrentInstance() {
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
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
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
    }
    
    private func reblogCommon(_ tootId: String, url: String) {
        if let currentAccount = Util.getCurrentAccount() {
            if let currentInstance = Util.getCurrentInstance() {
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
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
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
    }
    
    private func updateTitleView() {
        let titleLabel = UILabel()
        titleLabel.isUserInteractionEnabled = true
        titleLabel.text = Util.getCurrentAccount()?.acct
        titleLabel.sizeToFit()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TimelineViewController.openSelectAccountView(_:)))
        titleLabel.addGestureRecognizer(gestureRecognizer)
        self.parent!.navigationItem.titleView = titleLabel

    }
    
    private func setupRightBarButtonItems() {
        let item1 = UIBarButtonItem(title: "sign-out-alt", style: .plain, target: self, action: #selector(TimelineViewController.logout))
        item1.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome5FreeSolid", size: 20)], for: .normal)
        self.parent!.navigationItem.rightBarButtonItems = [item1]
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
