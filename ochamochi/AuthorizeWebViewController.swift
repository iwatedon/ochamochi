//
//  AuthorizeWebViewController.swift
//  ochamochi
//
//

import UIKit
import WebKit

class AuthorizeWebViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet var webView : WKWebView?
    var url: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView!.navigationDelegate = self
        webView!.translatesAutoresizingMaskIntoConstraints = false
        webView!.load(URLRequest(url: URL(string: url!)!))
        
        // Cookieを削除してログイン状態を解除しておく必要がある
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeCookies], modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
