//
//  SelectAccountTableViewController.swift
//  ochamochi
//
//

import UIKit
import RealmSwift

class SelectAccountTableViewController: UITableViewController {
    @IBOutlet var cancelButton : UIBarButtonItem?
    @IBOutlet var addButton : UIBarButtonItem?
    @IBOutlet var editButton : UIBarButtonItem?
    
    var accounts : [Account] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadAccounts()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return accounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let account = accounts[indexPath.row]
        cell.textLabel?.text = account.acct
        if (account.acct == Util.getCurrentAccount()?.acct) {
            cell.accessoryType = .checkmark
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = accounts[indexPath.row]
        Util.setCurrentAccount(account)
        
        // Update TableView
        let navigationController = presentingViewController as! UINavigationController
        if let controllers = (navigationController.topViewController as! UITabBarController).viewControllers {
            controllers.forEach { controller in
                (controller as! TimelineViewController).clearTimeline()
            }
        }
        
        dismiss(animated: true, completion: nil)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
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
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func add() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "NewInstanceView") {
            present(controller, animated: true, completion: nil)
        }
    }
    
    private func loadAccounts() {
        do {
            let realm = try Realm()
            let results = realm.objects(Account.self)
            results.forEach { account in
                accounts.append(account)
            }
        } catch {
            print(error)
        }
    }

}
