//
//  TimelineViewDelegate.swift
//  ochamochi
//

import Foundation
import UIKit

protocol TimelineViewDelegate {
    func tootTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
}

extension TimelineViewDelegate where Self: TimelineViewController {
    func tootTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TimelineViewCell
        
        cell.contentLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        
        let toot = toots[indexPath.row]
        
        cell.delegate = self
        cell.tootId = toot.id
        cell.accountId = toot.accountId
        
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
}
