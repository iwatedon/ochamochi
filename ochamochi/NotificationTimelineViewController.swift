//
//  NotificationTimelineViewController.swift
//  ochamochi
//

import UIKit
import OAuthSwift

class NotificationTimelineViewController: TimelineViewController {
    var notifications: [MastodonNotification] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
                self.tableView.register(UINib(nibName: "NotificationTimelineViewCell", bundle: nil), forCellReuseIdentifier: "NotificationCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateTitleView()
        
        setupRightBarButtonItems()
        
        if (notifications.count == 0) {
            loadTimeline()
        }
    }
    
    override func getTabBarIconName() -> String {
        return "bell"
    }
    
    override func getTimelineUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/notifications".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
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
    
    override func loadTimeline() {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            MastodonUtil.loadNotification(nil, maxId: nil, timelineUrl: self.getTimelineUrl(currentAccount.url), parameters: self.getParameters(since_id: nil, max_id: nil), success: { notifications, maxId in
                self.notifications = notifications
                self.currentMaxId = maxId
                self.tableView.reloadData()
                if (self.refreshControl!.isRefreshing) {
                    self.refreshControl!.endRefreshing()
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cancel all unused image loading tasks
        (cell as! NotificationTimelineViewCell).clearAllImages()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationTimelineViewCell
        
        cell.selectionStyle = .none
        
        let notification = notifications[indexPath.row]
        
        cell.delegate = self
        cell.accountId = notification.accountId
        
        switch notification.type {
        case "mention":
            cell.typeTextView?.text = "\(notification.accountDisplayName!)"
        case "reblog":
            cell.typeTextView?.text = "\(notification.accountDisplayName!) boosted your status."
        case "favourite":
            cell.typeTextView?.text = "\(notification.accountDisplayName!) favourited your status."
        case "follow":
            cell.typeTextView?.text = "\(notification.accountDisplayName!) follows you."
        default:
            cell.typeTextView?.text = "nothing."
        }
        
        if let _ = notification.tootId {
            cell.tootAvatarImageTask = cell.tootAvatarImageView?.imageAsync(urlString: notification.tootAccountAvatar!)
            if (notification.tootSpoilerText != "") {
                cell.contentTextView?.attributedText = NSMutableAttributedString(string: notification.tootSpoilerText!, attributes:[:])
            } else {
                cell.contentTextView?.attributedText = NSMutableAttributedString(string: notification.tootContent!, attributes:[:])
            }
        } else {
            cell.contentTextView?.attributedText = nil
        }
        
        cell.avatarImageTask = cell.avatarImageView?.imageAsync(urlString: notification.accountAvatar!)
        
        cell.layoutSubviews()
        
        return cell
        
    }
}
