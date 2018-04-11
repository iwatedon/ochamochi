//
//  FirstViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift

class HomeTimelineViewController: TimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func getTabBarIconName() -> String {
        return "home"
    }
    
    override func getTimelineUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/timelines/home".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
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
}

