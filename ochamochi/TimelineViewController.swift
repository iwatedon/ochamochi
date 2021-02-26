//
//  TimelineViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift
import RealmSwift
import DateToolsSwift
import Floaty

class TimelineViewController: UITableViewController, TimelineViewDelegate, TimelineViewCellDelegate {
    
    var toots : [Toot] = []
    
    var isLoading = false
    
    var useWebLinking = false
    
    var currentMaxId: String? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.tabBarItem.image = UIImage.fontAwesomeImage(name: self.getTabBarIconName(), textColor: UIColor.black, size: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate)
        self.tabBarItem.selectedImage = UIImage.fontAwesomeImage(name: self.getTabBarIconName(), textColor: UIColor.buttonDefault, size: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysTemplate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "TimelineViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.rowHeight = UITableViewAutomaticDimension
    
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(TimelineViewController.onRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    @objc func onRefresh(_ sender: UIRefreshControl) {
        refreshControl!.beginRefreshing()
        
        loadTimeline()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Setting title view
        updateTitleView()
        
        setupRightBarButtonItems()
        
        if (toots.count == 0) {
            loadTimeline()
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // cancel all unused image loading tasks
        (cell as! TimelineViewCell).clearAllImages()
    }
    
    // return max_id
    func loadTimeline() {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            MastodonUtil.loadTimeline(nil, maxId: nil, timelineUrl: self.getTimelineUrl(currentAccount.url), parameters: self.getParameters(since_id: nil, max_id: nil), success: { toots, maxId in
                self.toots = toots
                self.currentMaxId = maxId
                self.tableView.reloadData()
                if (self.refreshControl!.isRefreshing) {
                    self.refreshControl!.endRefreshing()
                }
            }, useWebLinking: useWebLinking)
        }
    }
    
    func loadTimeline(maxId: String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            MastodonUtil.loadTimeline(nil, maxId: maxId, timelineUrl: self.getTimelineUrl(currentAccount.url), parameters: self.getParameters(since_id: nil, max_id: maxId), success: { toots, _maxId in
                    self.toots = self.toots + toots
                    self.currentMaxId = _maxId
                    self.tableView.reloadData()
                    self.isLoading = false
            }, useWebLinking: useWebLinking)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toots.count
    }
    
    /* override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    } */
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tootTableView(tableView, cellForRowAt:indexPath)
    }
    
    var lock = NSLock()
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.toots.count > 0) {
            self.lock.lock()
            defer { self.lock.unlock() }
            if (isLoading == true) {
                return
            } else if tableView.contentOffset.y + tableView.frame.size.height > tableView.contentSize.height && tableView.isDragging {
                if let maxId = currentMaxId {
                    isLoading = true
                    loadTimeline(maxId: maxId)
                }
            }
        }
    }
    
    func clearTimeline() {
        toots = []
        self.tableView.reloadData()
    }
    
    func getTabBarIconName() -> String {
        return ""
    }
    
    func getTimelineUrl(_ url : String) -> String {
        return ""
    }
    
    func getParameters(since_id: String?, max_id: String?) -> OAuthSwift.Parameters {
        var result : [String:Any] = [:]
        if let _ = since_id {
            result["since_id"] = since_id! as Any
        }
        if let _ = max_id {
            result["max_id"] = max_id! as Any
        }
        return result
    }
    
    @objc func logout() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(MastodonUtil.getCurrentAccount()!)
            }
            let accounts = realm.objects(Account.self)
            if (accounts.count > 0) {
                // change current account to first
                MastodonUtil.setCurrentAccount(accounts[0])
                
                // invalidate all timelines
                if let controllers = (self.parent as! UITabBarController).viewControllers {
                    controllers.forEach { controller in
                        let timeline = controller as! TimelineViewController
                        timeline.clearTimeline()
                        timeline.viewWillAppear(false)
                    }
                }
            } else {
                // go to new instance view
                self.parent?.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        } catch {
            print(error)
        }
    }
    
    @objc func openSelectAccountView(_ sender: UILabel) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "SelectAccountView") {
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    
    func updateTitleView() {
        let titleLabel = UILabel()
        titleLabel.isUserInteractionEnabled = true
        titleLabel.text = MastodonUtil.getCurrentAccount()?.acct
        titleLabel.sizeToFit()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TimelineViewController.openSelectAccountView(_:)))
        titleLabel.addGestureRecognizer(gestureRecognizer)
        self.parent!.navigationItem.titleView = titleLabel

    }
    
    func setupRightBarButtonItems() {
        let item1 = UIBarButtonItem(title: "sign-out-alt", style: .plain, target: self, action: #selector(TimelineViewController.logout))
        item1.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "FontAwesome5FreeSolid", size: 20) ?? "hoge"], for: .normal)
        self.parent!.navigationItem.rightBarButtonItems = [item1]
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
