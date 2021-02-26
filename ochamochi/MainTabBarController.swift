//
//  MainTabBarController.swift
//  ochamochi
//
//

import UIKit
import Floaty

class MainTabBarController: UITabBarController, FloatyDelegate, UITabBarControllerDelegate {
    var floaty: Floaty? = nil
    
    // use to scrolling tableviews to top when tapping tabbar.
    var previousController: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        
        floaty = Floaty()
        floaty!.fabDelegate = self
        floaty!.sticky = true
        floaty!.friendlyTap = false
        floaty!.paddingY = floaty!.paddingY + 49.0
        self.view.addSubview(floaty!)
        
        self.previousController = self.viewControllers?.first
    }
    
    func emptyFloatySelected(_ floaty: Floaty) {
        toot()
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if (viewController is UITableViewController && viewController == previousController) {
            let _controller = viewController as! UITableViewController
            if (_controller.tableView.numberOfSections > 0 && _controller.tableView.numberOfRows(inSection: 0) > 0) {
                _controller.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        previousController = viewController
    }
    
    func toot() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "MakeTootView") {
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
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
