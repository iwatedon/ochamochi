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
    @IBOutlet var contentLabel: UITextView?
    @IBOutlet var avatarImageView: UIImageView?
    
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
    
    var delegate: TimelineViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TimelineViewCell.tappedImageView(_:)))
        gestureRecognizer.delegate = self
        avatarImageView?.addGestureRecognizer(gestureRecognizer)
        
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
