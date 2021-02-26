//
//  SelectInstanceViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift
import RealmSwift
import SafariServices

class NewInstanceViewController: UIViewController {
    @IBOutlet var urlTextField: UITextField?
    @IBOutlet var okButton : UIButton?
    
    var oauthswift : OAuth2Swift? // retain

    override func viewDidLoad() {
        super.viewDidLoad()

        // Disable auto correction
        urlTextField?.autocorrectionType = .no
        urlTextField?.autocapitalizationType = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // If currentAccount is set. Show MainTabBarController directly.
        if (self.presentingViewController == nil) {
            if let _ = MastodonUtil.getCurrentAccount() {
                let controller = UINavigationController(rootViewController: UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainTabView"))
                controller.modalPresentationStyle = .fullScreen
                present(controller, animated: false, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onOKButtonTapped(_ sender: UIButton) {
        if let url = urlTextField?.text {
            let realm = try! Realm()
            let instances = realm.objects(Instance.self).filter(NSPredicate(format: "url = %@", url))
            if (instances.count == 0) {
                // Get client_key and client_secrent without authentication
                oauthswift = OAuth2Swift(consumerKey: "", consumerSecret: "", authorizeUrl: "", responseType: "")
                oauthswift!.client.post(self.appUrl(url),
                                       parameters: ["client_name" : "ochamochi",
                                                    "redirect_uris" : "oauth-swift://oauth-callback/ochamochi",
                                                    "scopes" : "read write follow",
                                                    "website" : "https://github.com/iwatedon/ochamochi"]) { result in
                    switch result {
                    case .success(let response):
                        self.parseResponseJson(response.string!, url: url)
                    case .failure(let error):
                        print(error)
                    }
                }
            } else {
                let instance = instances[0]
                openAuthorizeUrl(instance)
            }
        }
    }
    
    @IBAction func urlTextFieldDidBeginEditing(_ sender: UITextField) {
        sender.perform(#selector(selectAll(_:)), with: nil, afterDelay: 0.1)
    }
    
    private func appUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/apps"
    }
    
    // Get authorize URL
    private func getAuthorizeUrl(_ instance: Instance) -> String {
        return "https://\(instance.url)/oauth/authorize".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func getAccessTokenUrl(_ instance: Instance) -> String {
        return "https://\(instance.url)/oauth/token".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    private func verifyCredentialsUrl(_ instance: Instance) -> String {
        return "https://\(instance.url)/api/v1/accounts/verify_credentials"
    }
    
    // Parse response JSON and write instance data to Realm
    private func parseResponseJson(_ response: String, url: String) {
        do {
            let json = try JSONSerialization.jsonObject(with: response.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
            let dict = json as! [String:Any]
            let instance = Instance()
            instance.url = url
            instance.clientId = dict["client_id"] as! String
            instance.clientSecret = dict["client_secret"] as! String
            
            let realm = try! Realm()
            try realm.write {
                realm.add(instance)
                print("write " + url)
            }
            
            DispatchQueue.main.async {
                self.openAuthorizeUrl(instance)
            }
        } catch {
            print(error)
        }
    }
    
    private func getAccountInfo(instance: Instance, account: Account) {
        var currentAccount : Account? = nil
        let _  = oauthswift!.client.get(self.verifyCredentialsUrl(instance)) { result in
            switch result {
            case .success(let response):
                do {
                    // set acct to Account and save
                    let dataString = response.string
                    let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                    let dict = json as! [String:Any]
                    let acct = (dict["acct"] as! String) + "@" + instance.url
                    let realm = try! Realm()
                    let accounts = realm.objects(Account.self).filter(NSPredicate(format: "acct = %@", acct))
                    if (accounts.count == 0) {
                        try realm.write {
                            account.acct = acct
                            realm.add(account)
                            currentAccount = account
                        }
                    } else {
                         currentAccount = accounts[0]
                    }
                    MastodonUtil.setCurrentAccount(currentAccount!)
                    DispatchQueue.main.async {
                        self.presentMainTabBarController()
                    }
                } catch {
                    print(error)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func presentMainTabBarController() {
        if (presentingViewController == nil) {
            // not modal
            if let controller = storyboard?.instantiateViewController(withIdentifier: "MainTabView") {
                let navigationController = UINavigationController(rootViewController: controller)
                navigationController.modalPresentationStyle = .fullScreen
                self.view.window?.rootViewController?.present(navigationController, animated: true, completion: nil)
            }
        } else {
            // modal
            
            // Update TableView
            let navigationController = presentingViewController?.presentingViewController as! UINavigationController
            if let controllers = (navigationController.topViewController as! UITabBarController).viewControllers {
                controllers.forEach { controller in
                    (controller as! TimelineViewController).clearTimeline()
                }
            }
            
            presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func openAuthorizeUrl(_ instance: Instance) {
        let authorizeUrl = self.getAuthorizeUrl(instance)
        let accessTokenUrl = self.getAccessTokenUrl(instance)
        oauthswift = OAuth2Swift(consumerKey: instance.clientId, consumerSecret: instance.clientSecret, authorizeUrl: authorizeUrl, accessTokenUrl: accessTokenUrl, responseType: "code")
        //oauthswift?.authorizeURLHandler = SafariURLHandler(viewController: self, oauthSwift: oauthswift!)
        oauthswift?.authorizeURLHandler = AuthorizeWebViewController()
        
        oauthswift!.authorize(withCallbackURL: "oauth-swift://oauth-callback/ochamochi", scope: "read write follow", state: "OCHAMOCHI") { result in
            switch result {
            case .success(let (credential, response, parameters)):
                let account = Account()
                account.url = instance.url
                account.accessToken = credential.oauthToken
                
                self.getAccountInfo(instance: instance, account: account)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
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
