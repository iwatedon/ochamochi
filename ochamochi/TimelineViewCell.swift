//
//  TimelineViewCell.swift
//  ochamochi
//
//

import Foundation
import UIKit
import SafariServices

class TimelineViewCell : UITableViewCell, UITextViewDelegate {
    @IBOutlet var displayNameLabel: UILabel?
    @IBOutlet var acctLabel: UILabel?
    @IBOutlet var createdAtLabel: UILabel?
    
    @IBOutlet var spoilerTextView: UITextView?
    @IBOutlet var spoilerTextViewHeight: NSLayoutConstraint?
    @IBOutlet var spoilerTextViewHeightZero: NSLayoutConstraint?
    @IBOutlet var spoilerTextViewTopSpace: NSLayoutConstraint?
    
    @IBOutlet var showContentButton: UIButton?
    
    @IBOutlet var contentContainerView: UIView?
    @IBOutlet var contentContainerViewHeight: NSLayoutConstraint?
    
    @IBOutlet var contentLabel: UITextView?
    @IBOutlet var avatarImageView: UIImageView?
    
    @IBOutlet var attachmentImageView1: UIImageView?
    @IBOutlet var attachmentImageViewHeight1: NSLayoutConstraint?
    @IBOutlet var attachmentImageViewTopSpace1: NSLayoutConstraint?
    
    @IBOutlet var attachmentImageView2: UIImageView?
    @IBOutlet var attachmentImageViewHeight2: NSLayoutConstraint?
    @IBOutlet var attachmentImageViewTopSpace2: NSLayoutConstraint?
    
    @IBOutlet var attachmentImageView3: UIImageView?
    @IBOutlet var attachmentImageViewHeight3: NSLayoutConstraint?
    @IBOutlet var attachmentImageViewTopSpace3: NSLayoutConstraint?
    
    @IBOutlet var attachmentImageView4: UIImageView?
    @IBOutlet var attachmentImageViewHeight4: NSLayoutConstraint?
    @IBOutlet var attachmentImageViewTopSpace4: NSLayoutConstraint?
    
    @IBOutlet var boostLabel: UILabel?
    @IBOutlet var boostLabelHeight : NSLayoutConstraint?
    
    @IBOutlet var replyButton: UIButton?
    @IBOutlet var boostButton: UIButton?
    @IBOutlet var favButton: UIButton?
    @IBOutlet var deleteButton: UIButton?
    
    var tootId : String? = nil
    var favourited : Bool? = false
    var boosted: Bool? = false
    
    var accountId: String? = nil
    var accountAcct: String? = nil
    
    var mentions: [Mention] = []
    var attachments: [Attachment] = []
    
    var delegate: TimelineViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.tappedImageView(_:)))
        gestureRecognizer.delegate = self
        avatarImageView?.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.attachmentImageView1Tapped(_:)))
        gestureRecognizer1.delegate = self
        attachmentImageView1?.addGestureRecognizer(gestureRecognizer1)
        let gestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.attachmentImageView2Tapped(_:)))
        gestureRecognizer2.delegate = self
        attachmentImageView2?.addGestureRecognizer(gestureRecognizer2)
        let gestureRecognizer3 = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.attachmentImageView3Tapped(_:)))
        gestureRecognizer3.delegate = self
        attachmentImageView3?.addGestureRecognizer(gestureRecognizer3)
        let gestureRecognizer4 = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.attachmentImageView4Tapped(_:)))
        gestureRecognizer4.delegate = self
        attachmentImageView4?.addGestureRecognizer(gestureRecognizer4)
        
        spoilerTextView?.textContainerInset = UIEdgeInsets.zero
        spoilerTextView?.textContainer.lineFragmentPadding = 0
        spoilerTextView?.delegate = self
        
        contentLabel?.textContainerInset = UIEdgeInsets.zero
        contentLabel?.textContainer.lineFragmentPadding = 0
        contentLabel?.delegate = self
    }
    
    func tappedImageView(_ sender: UITapGestureRecognizer) {
        if (accountId != nil) {
            delegate?.accountDetail(accountId!)
        }
    }
    
    @IBAction func replyButtonTapped(_ sender: UIButton?) {
        if (tootId != nil) {
            delegate?.reply(self.tootId!)
        }
    }
    
    @IBAction func favButtonTapped(_ sender: UIButton?) {
        if (favourited != nil && favourited == true) {
            delegate?.unfav(self.tootId!)
        } else {
            delegate?.fav(self.tootId!)
        }
    }
    
    @IBAction func boostButtonTapped(_ sender: UIButton?) {
        if (boosted != nil && boosted == true) {
            delegate?.unreblog(self.tootId!)
        } else {
            delegate?.reblog(self.tootId!)
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton?) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if (MastodonUtil.normalizeAcct(accountAcct!) == currentAccount.acct) {
                delegate?.confirmDelete(self.tootId!)
            }
        }
    }
    
    @IBAction func showButtonTapped(_ sender: UIButton?) {
        (delegate as! UITableViewController).tableView.beginUpdates()
        if (sender?.titleLabel?.text == "Show") {
            self.contentContainerView?.isHidden = false
            self.contentContainerViewHeight?.isActive = false
            sender?.setTitle("Hide", for: .normal)
        } else {
            self.contentContainerView?.isHidden = true
            self.contentContainerViewHeight?.isActive = true
            sender?.setTitle("Show", for: .normal)
        }
        (delegate as! UITableViewController).tableView.endUpdates()
    }
    
    @IBAction func attachmentImageView1Tapped(_ sender: UIImageView?) {
        attachmentImageViewTapped(sender, index: 0)
    }
    
    @IBAction func attachmentImageView2Tapped(_ sender: UIImageView?) {
        attachmentImageViewTapped(sender, index: 1)
    }
    
    @IBAction func attachmentImageView3Tapped(_ sender: UIImageView?) {
        attachmentImageViewTapped(sender, index: 2)
    }
    
    @IBAction func attachmentImageView4Tapped(_ sender: UIImageView?) {
        attachmentImageViewTapped(sender, index: 3)
    }
    
    private func attachmentImageViewTapped(_ sender: UIImageView?, index: Int) {
        let attachment = attachments[index]
        delegate?.attachmentDetail(attachment)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return interactURL(URL: URL)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return interactURL(URL: URL)
    }
    
    private func interactURL(URL: URL) -> Bool{
        if (URL.scheme == "mailto") {
            let acct = String(URL.absoluteString.split(separator: ":")[1])
            self.mentions.forEach { mention in
                if (MastodonUtil.normalizeAcct(mention.acct!) == acct) {
                    delegate?.accountDetail(mention.id!)
                }
            }
        }
        return true
    }
}
