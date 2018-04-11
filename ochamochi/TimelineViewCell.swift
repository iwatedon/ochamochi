//
//  TimelineViewCell.swift
//  ochamochi
//
//

import Foundation
import UIKit

class TimelineViewCell : UITableViewCell {
    @IBOutlet var displayNameLabel: UILabel?
    @IBOutlet var acctLabel: UILabel?
    @IBOutlet var createdAtLabel: UILabel?
    @IBOutlet var contentLabel: UILabel?
    @IBOutlet var avatarImageView: UIImageView?
    
    @IBOutlet var boostLabel: UILabel?
    @IBOutlet var boostLabelHeight : NSLayoutConstraint?
    
    @IBOutlet var replyButton: UIButton?
    @IBOutlet var boostButton: UIButton?
    @IBOutlet var favButton: UIButton?
    
    var tootId : String? = nil
    var favourited : Bool? = false
    var boosted: Bool? = false
    var delegate: TimelineViewCellDelegate? = nil
    
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
}
