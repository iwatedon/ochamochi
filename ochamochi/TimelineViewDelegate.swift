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
        
        cell.selectionStyle = .none
        
        let toot = toots[indexPath.row]
        
        cell.delegate = self
        cell.tootId = toot.id
        cell.accountId = toot.accountId
        cell.accountAcct = toot.accountAcct
        cell.mentions = toot.mentions
        cell.attachments = toot.attachments
        
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
                    
                    cell.contentLabel?.attributedText = cell.contentLabel?.attributedText.replaceEmoji(pattern: ":\(emoji.shortcode!):", replacement: NSAttributedString(attachment: attachment))
                } else {
                    print(error)
                }
            }).resume()
        }
        
        cell.displayNameLabel?.text = toot.accountDisplayName!
        cell.acctLabel?.text = "@" + toot.accountAcct!
        cell.createdAtLabel?.text = toot.createdAt?.shortTimeAgoSinceNow
        
        // load media
        cell.attachmentImageViewHeight1?.constant = 0
        cell.attachmentImageViewHeight2?.constant = 0
        cell.attachmentImageViewHeight3?.constant = 0
        cell.attachmentImageViewHeight4?.constant = 0
        
        cell.attachmentImageViewTopSpace1?.constant = 0
        cell.attachmentImageViewTopSpace2?.constant = 0
        cell.attachmentImageViewTopSpace3?.constant = 0
        cell.attachmentImageViewTopSpace4?.constant = 0
        
        cell.attachmentImageView1?.isHidden = true
        cell.attachmentImageView2?.isHidden = true
        cell.attachmentImageView3?.isHidden = true
        cell.attachmentImageView4?.isHidden = true
        
        if (toot.attachments.count > 0) {
            cell.attachmentImageViewHeight1?.constant = 100
            cell.attachmentImageViewTopSpace1?.constant = 10
            cell.attachmentImageView1?.isHidden = false
            
            // load attachment1
            self.loadAttachmentPreview(url: toot.attachments[0].previewUrl!, imageView: cell.attachmentImageView1!, cell: cell)
            
            if (toot.attachments.count > 1) {
                cell.attachmentImageViewHeight2?.constant = 100
                cell.attachmentImageViewTopSpace2?.constant = 10
                cell.attachmentImageView2?.isHidden = false
                
                // load attachment2
                self.loadAttachmentPreview(url: toot.attachments[1].previewUrl!, imageView: cell.attachmentImageView2!, cell: cell)
                
                if (toot.attachments.count > 2) {
                    cell.attachmentImageViewHeight3?.constant = 100
                    cell.attachmentImageViewTopSpace3?.constant = 10
                    cell.attachmentImageView3?.isHidden = false
                    
                    // load attachment3
                    self.loadAttachmentPreview(url: toot.attachments[2].previewUrl!, imageView: cell.attachmentImageView3!, cell: cell)
                    
                    if (toot.attachments.count > 3) {
                        cell.attachmentImageViewHeight4?.constant = 100
                        cell.attachmentImageViewTopSpace4?.constant = 10
                        cell.attachmentImageView4?.isHidden = false
                        
                        // load attachment4
                        self.loadAttachmentPreview(url: toot.attachments[3].previewUrl!, imageView: cell.attachmentImageView4!, cell: cell)
                        
                    }
                    
                }
                
            }
        }
        
        if (toot.boosted) {
            cell.boostLabel?.isHidden = false
            cell.boostLabel?.text = "\(toot.boostAccontDisplayName!) boosted"
            cell.boostLabelHeight?.constant = 15
        } else {
            cell.boostLabel?.isHidden = true
            cell.boostLabelHeight?.constant = 0
        }
        
        cell.replyButton?.setTitleColor(UIColor.gray, for: .normal)
        cell.replyButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 20)
        
        if (toot.visibility == "private") {
            cell.boostButton?.setTitle("lock", for: .normal)
            cell.boostButton?.isEnabled = false
            cell.boostButton?.setTitleColor(UIColor.gray, for: .normal)
        } else if (toot.visibility == "direct") {
            cell.boostButton?.setTitle("envelope", for: .normal)
            cell.boostButton?.isEnabled = false
            cell.boostButton?.setTitleColor(UIColor.gray, for: .normal)
        } else if let reblogged = toot.reblogged {
            cell.boostButton?.setTitle("retweet", for: .normal)
            cell.boostButton?.isEnabled = true
            cell.boosted = reblogged
            cell.boostButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 20)
            if (reblogged) {
                cell.boostButton?.setTitleColor(UIColor.buttonDefault, for: .normal)
            } else {
                cell.boostButton?.setTitleColor(UIColor.gray, for: .normal)
            }
        }
        
        if let favourited = toot.favourited {
            cell.favourited = favourited
            if (favourited) {
                cell.favButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 20)
                cell.favButton?.setTitleColor(UIColor.buttonDefault, for: .normal)
            } else {
                cell.favButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeRegular", size: 20)
                cell.favButton?.setTitleColor(UIColor.gray, for: .normal)
            }
        }
        
        cell.deleteButton?.titleLabel?.font = UIFont(name: "FontAwesome5FreeSolid", size: 20)
        cell.deleteButton?.setTitleColor(UIColor.gray, for: .normal)
        cell.deleteButton?.isHidden = (MastodonUtil.normalizeAcct(toot.accountAcct!) != MastodonUtil.getCurrentAccount()?.acct)
        
        // read avatar image
        DispatchQueue.global().async {
            if let imageUrl = URL(string: toot.accountAvatar!) {
                let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, err) in
                    if (err == nil) {
                        DispatchQueue.main.async {
                            cell.avatarImageView!.image = UIImage(data: data!)?.resize(size: CGSize(width:60, height:60))
                            // cell.layoutSubviews()
                        }
                    }
                }
                task.resume()
            }
        }
        
        cell.layoutSubviews()
        
        return cell
    }
    
    // load attachment preview image
    private func loadAttachmentPreview(url: String, imageView: UIImageView, cell: UITableViewCell) {
        DispatchQueue.global().async {
            if let imageUrl = URL(string: url) {
                let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, err) in
                    if (err == nil) {
                        DispatchQueue.main.async {
                            imageView.image = UIImage(data: data!)?.croppedImage(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
                            // cell.layoutSubviews()
                        }
                    }
                }
                task.resume()
            }
        }
    }
}
