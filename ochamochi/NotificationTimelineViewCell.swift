//
//  NotificationTimelineViewCell.swift
//  ochamochi
//
//  Created by さとうおさむ on 2018/04/23.
//

import UIKit

class NotificationTimelineViewCell: UITableViewCell {
    @IBOutlet var typeTextView : UITextView?
    @IBOutlet var contentTextView : UITextView?
    
    @IBOutlet var avatarImageView : AsyncImageView?
    var avatarImageTask : URLSessionDataTask? = nil
    
    @IBOutlet var tootAvatarImageView: AsyncImageView?
    var tootAvatarImageTask : URLSessionDataTask? = nil
    
    var accountId : String? = nil
    
    var delegate: TimelineViewCellDelegate? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NotificationTimelineViewCell.tappedImageView(_:)))
        gestureRecognizer.delegate = self
        avatarImageView?.addGestureRecognizer(gestureRecognizer)
        
        typeTextView?.textContainerInset = UIEdgeInsets.zero
        typeTextView?.textContainer.lineFragmentPadding = 0
        
        contentTextView?.textContainerInset = UIEdgeInsets.zero
        contentTextView?.textContainer.lineFragmentPadding = 0
        contentTextView?.textContainer.lineBreakMode = .byTruncatingTail
        contentTextView?.textContainer.maximumNumberOfLines = 2
    }
    
    override func prepareForReuse() {
        clearAllImages()
    }
    
    func tappedImageView(_ sender: UITapGestureRecognizer) {
        if (accountId != nil) {
            delegate?.accountDetail(accountId!)
        }
    }
    
    func clearAllImages() {
        // cancel image loading tasks
        if let task = avatarImageTask { task.cancel() }
        if let task = tootAvatarImageTask { task.cancel() }
        
        // clear images
        avatarImageView?.image = nil
        tootAvatarImageView?.image = nil
    }
}
