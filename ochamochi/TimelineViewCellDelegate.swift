//
//  TimelineViewCellDelegate.swift
//  ochamochi
//
//

import Foundation

protocol TimelineViewCellDelegate {
    func reply(_ tootId: String)
    func fav(_ tootId: String)
    func unfav(_ tootId: String)
    func reblog(_ tootId: String)
    func unreblog(_ tootId: String)
}
