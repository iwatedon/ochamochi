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
        cell.accountAvatar = toot.accountAvatar
        cell.mentions = toot.mentions
        cell.attachments = toot.attachments
        
        if let spoiler_text = toot.spoilerText {
            if (spoiler_text != "" && toot.sensitive == true) {
                // CW
                showSpoilerTextView(cell)
                cell.spoilerTextView?.attributedText = NSMutableAttributedString(string: spoiler_text, attributes: [:])
                
                cell.showContentButton?.isHidden = false
                
                cell.showContentButton?.setTitle("Show", for: .normal)
                
                cell.contentContainerView?.isHidden = true
                cell.contentContainerViewHeight?.isActive = true
            } else {
                hideSpoilerTextView(cell)
                cell.showContentButton?.isHidden = true
                
                cell.contentContainerView?.isHidden = false
                cell.contentContainerViewHeight?.isActive = false
            }
        } else {
            hideSpoilerTextView(cell)
            cell.showContentButton?.isHidden = true
            
            cell.contentContainerView?.isHidden = false
        }
        
        let contentAttributedText = NSMutableAttributedString(string: toot.content!, attributes:[:])
        cell.contentLabel?.attributedText = contentAttributedText
        
        cell.contentLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.spoilerTextView?.font = UIFont.systemFont(ofSize: 16)
        
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
                    
                    if (toot.sensitive == true) {
                    cell.spoilerTextView?.attributedText = cell.spoilerTextView?.attributedText.replaceEmoji(pattern: ":\(emoji.shortcode!):", replacement: NSAttributedString(attachment: attachment))
                    }
                    
                    cell.contentLabel?.font = UIFont.systemFont(ofSize: 16)
                    cell.spoilerTextView?.font = UIFont.systemFont(ofSize: 16)
                } else {
                    print(error)
                }
            }).resume()
        }
        
        if (toot.accountDisplayName! != "") {
            cell.displayNameLabel?.text = toot.accountDisplayName!
        } else {
            cell.displayNameLabel?.text = String(toot.accountAcct!.split(separator: "@").first!)
        }
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
            if (toot.sensitive == false) {
                cell.attachmentImageView1Task = cell.attachmentImageView1?.imageAsync(urlString: toot.attachments[0].previewUrl!)
            }
            
            if (toot.attachments.count > 1) {
                cell.attachmentImageViewHeight2?.constant = 100
                cell.attachmentImageViewTopSpace2?.constant = 10
                cell.attachmentImageView2?.isHidden = false
                
                // load attachment2
                if (toot.sensitive == false) {
                    cell.attachmentImageView2Task =  cell.attachmentImageView2?.imageAsync(urlString: toot.attachments[1].previewUrl!)
                }
                
                if (toot.attachments.count > 2) {
                    cell.attachmentImageViewHeight3?.constant = 100
                    cell.attachmentImageViewTopSpace3?.constant = 10
                    cell.attachmentImageView3?.isHidden = false
                    
                    // load attachment3
                    if (toot.sensitive == false) {
                        cell.attachmentImageView3Task = cell.attachmentImageView3?.imageAsync(urlString: toot.attachments[2].previewUrl!)
                    }
                    
                    if (toot.attachments.count > 3) {
                        cell.attachmentImageViewHeight4?.constant = 100
                        cell.attachmentImageViewTopSpace4?.constant = 10
                        cell.attachmentImageView4?.isHidden = false
                        
                        // load attachment4
                        if (toot.sensitive == false) {
                            cell.attachmentImageView4Task =   cell.attachmentImageView4?.imageAsync(urlString: toot.attachments[3].previewUrl!)
                        }
                        
                    }
                    
                }
                
            }
        }
        
        if (toot.boosted) {
            cell.boostLabel?.isHidden = false
            cell.boostLabel?.text = "\(toot.boostAccontDisplayName!) boosted"
            cell.boostLabelHeight?.constant = 15
            cell.boostLabelBottomSpace?.constant = 5
        } else {
            cell.boostLabel?.isHidden = true
            cell.boostLabelHeight?.constant = 0
            cell.boostLabelBottomSpace?.constant = 0
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
        cell.avatarImageTask = cell.avatarImageView?.imageAsync(urlString: toot.accountAvatar!)
        
        cell.layoutSubviews()
        
        return cell
    }
    
    private func hideSpoilerTextView(_ cell: TimelineViewCell) {
        cell.spoilerTextView?.isHidden = true
        cell.spoilerTextViewHeightZero?.isActive = true
        cell.spoilerTextViewHeight?.isActive = false
        cell.spoilerTextViewTopSpace?.constant = 0
    }
    
    private func showSpoilerTextView(_ cell: TimelineViewCell) {
        cell.spoilerTextView?.isHidden = false
        cell.spoilerTextViewHeightZero?.isActive = false
        cell.spoilerTextViewHeight?.isActive = true
        cell.spoilerTextViewTopSpace?.constant = 10
    }
}
