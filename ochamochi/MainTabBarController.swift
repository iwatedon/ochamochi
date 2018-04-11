//
//  MainTabBarController.swift
//  ochamochi
//
//

import UIKit
import Floaty

class MainTabBarController: UITabBarController, FloatyDelegate {
    var floaty: Floaty? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        floaty = Floaty()
        floaty!.fabDelegate = self
        floaty!.sticky = true
        floaty!.friendlyTap = false
        floaty!.paddingY = floaty!.paddingY + 49.0
        self.view.addSubview(floaty!)
    }
    
    func emptyFloatySelected(_ floaty: Floaty) {
        toot()
    }
    
    
    func toot() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "MakeTootView") {
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
