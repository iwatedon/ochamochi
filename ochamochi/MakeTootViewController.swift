//
//  MakeTootViewController.swift
//  ochamochi
//
//

import UIKit
import OAuthSwift

class MakeTootViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var textView: UITextView?
    @IBOutlet var tootButton: UIBarButtonItem?
    @IBOutlet var cancelButton : UIBarButtonItem?
    
    @IBOutlet var replyView: UIView?
    @IBOutlet var replyViewHeight: NSLayoutConstraint?
    
    @IBOutlet var avatarImageView: UIImageView?
    
    @IBOutlet var displayNameLabel: UILabel?
    @IBOutlet var acctLabel: UILabel?
    @IBOutlet var contentLabel: UILabel?
    
    @IBOutlet var visibilityButton : UIButton?
    @IBOutlet var visibilityText : UILabel?
    
    @IBOutlet var customEmojiButton : UIButton?
    
    @IBOutlet var photoButton: UIButton?
    
    @IBOutlet var imageView1 : UIImageView?
    @IBOutlet var imageView2 : UIImageView?
    @IBOutlet var imageView3 : UIImageView?
    @IBOutlet var imageView4 : UIImageView?
    
    @IBOutlet var deleteImage1Button: UIButton?
    @IBOutlet var deleteImage2Button: UIButton?
    @IBOutlet var deleteImage3Button: UIButton?
    @IBOutlet var deleteImage4Button: UIButton?
    
    var inReplyToId : String?

    var visibility: String? = nil
    
    var images : [UIImage] = []
    var media_ids : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add border to TextView
        textView?.layer.borderColor = UIColor.gray.cgColor
        textView?.layer.borderWidth = 1.0
        textView?.layer.cornerRadius = 10.0
        textView?.layer.masksToBounds = true
        
        self.visibility = "public"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (inReplyToId == nil) {
            // Remove reply view components.
            replyView?.subviews.forEach { subview in
                subview.removeFromSuperview()
            }
            replyViewHeight?.constant = 0.0
            replyViewHeight?.priority = 1000
        } else {
            loadStatus(inReplyToId!)
        }
    }
    
    // load status of reply source
    func loadStatus(_ statusId:  String) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(
                    statusUrl(currentAccount.url, statusId: statusId),
                    success: { response in
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let t = json as! [String:Any]
                            
                            let content  = (t["content"] as? String)?.removeHTMLTag()
                            let spoilerText = t["spoiler_text"] as? String
                            
                            let a = t["account"] as! [String:Any]
                            
                            let accountAcct = a["acct"] as? String
                            let accountDisplayName = a["display_name"] as? String
                            let accountAvatar = a["avatar"] as? String
                            
                            self.displayNameLabel?.text = accountDisplayName
                            self.acctLabel?.text = accountAcct
                            self.contentLabel?.text = content
                            
                            // add acct first unless it is reply to your toot.
                            if (accountAcct != currentAccount.acct) {
                                self.textView?.text = "@\(accountAcct!) "
                            }
                            
                            // read avatar image
                            DispatchQueue.global().async {
                                if let imageUrl = URL(string: accountAvatar!) {
                                    let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                                    let task = URLSession.shared.dataTask(with: request) {
                                        (data, response, err) in
                                        if (err == nil) {
                                            DispatchQueue.main.async {
                                                self.avatarImageView!.image = UIImage(data: data!)?.resize(size: CGSize(width:60, height:60))
                                            }
                                        }
                                    }
                                    task.resume()
                                }
                            }
                            
                            if let _ = t["emojis"] {
                                var emojis = t["emojis"] as! [Any]
                                emojis.forEach { _emoji in
                                    let tmp = _emoji as! [String:Any]
                                    let emoji = Emoji()
                                    emoji.shortcode = tmp["shortcode"] as! String
                                    emoji.url = tmp["url"] as! String
                                    emoji.staticUrl = tmp["static_url"] as! String
                                    emojis.append(emoji)
                                }
                                
                                // replace emojis
                            }
                            
                            
                        } catch {
                            print(error)
                        }
                }, failure: {
                    error in
                    print(error.localizedDescription)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Make toot
    @IBAction func toot(_ sender: UIBarButtonItem) {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.post(
                    makeTootUrl(currentInstance.url),
                    parameters: self.tootParameters(),
                    success: {
                        response in
                        self.dismiss(animated: true, completion: nil)
                    }, failure: {
                        error in
                        print(error.localizedDescription)
                        self.dismiss(animated: true, completion: nil)
                    })
            }
        }
    }
    
    // parameters for tooting.
    private func tootParameters() -> [String:Any] {
        var parameters = ["status":(textView!.text! as Any),
                "visibility": self.visibility!]
        if (inReplyToId != nil) {
            parameters["in_reply_to_id"] = inReplyToId
        }
        if (media_ids.count > 0) {
            parameters["media_ids"] = media_ids
        }
        
        return parameters
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func visibilityButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Visibility", message : "Select toot visibility", preferredStyle: .actionSheet)
        let emojis : DictionaryLiteral = ["public" : "globe",
                                          "unlisted": "lock-open",
                                          "private": "lock",
                                          "direct": "envelope"]
        emojis.forEach {key, value in
            let action = UIAlertAction(title: key, style: .default, handler: {
                (_ : UIAlertAction!) in
                self.visibility = key
                self.visibilityButton!.setTitle(value, for: .normal)
                self.visibilityText?.text = key
            })
            if self.visibility == key {
                action.setValue(true, forKey: "checked")
            }
            actionSheet.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (_ : UIAlertAction!) in
        })
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func customEmojiButtonTapped(_ sender : UIButton) {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "CustomEmojiPickerView") {
            (controller as! CustomEmojiPickerViewController).previousController = self
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func photoButtonTapped(_ sender: UIButton) {
        if (self.images.count <= 3) {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let pickerView = UIImagePickerController()
                pickerView.sourceType = .photoLibrary
                pickerView.delegate = self
                self.present(pickerView, animated: true)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                
                let fileData = OAuthSwiftMultipartData(name: "file", data: UIImageJPEGRepresentation(image, 0.9)!, fileName: "file.jpg", mimeType: "image/jpeg")
                let multiparts = [fileData]
                let _ = oauthswift.client.postMultiPartRequest(
                    mediaUrl(currentInstance.url),
                    method: .POST,
                    parameters: [:],
                    multiparts: multiparts,
                    success: {
                        response in
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let media = json as! [String:Any]
                            
                            self.images.append(image)
                            self.media_ids.append(media["id"] as! String)
                            
                            self.refreshImages()
                            
                            self.dismiss(animated: true, completion: nil)
                        } catch {
                            print(error)
                        }
                }, failure: {
                    error in
                    print(error.localizedDescription)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
    
    func refreshImages() {
        for idx in 0...3 {
            if (self.images.count >= idx+1) {
                if (idx == 0) {
                    self.imageView1!.image = self.images[0]
                    self.deleteImage1Button?.isHidden = false
                } else if (idx == 1) {
                    self.imageView2!.image = self.images[1]
                    self.deleteImage2Button?.isHidden = false
                } else if (idx == 2) {
                    self.imageView3!.image = self.images[2]
                    self.deleteImage3Button?.isHidden = false
                } else if (idx == 3) {
                    self.imageView4!.image = self.images[3]
                    self.deleteImage4Button?.isHidden = false
                }
                
            } else {
                if (idx == 0) {
                    self.imageView1!.image = nil
                    self.deleteImage1Button?.isHidden = true
                } else if (idx == 1) {
                    self.imageView2!.image = nil
                    self.deleteImage2Button?.isHidden = true
                } else if (idx == 2) {
                    self.imageView3!.image = nil
                    self.deleteImage3Button?.isHidden = true
                } else if (idx == 3) {
                    self.imageView4!.image = nil
                    self.deleteImage4Button?.isHidden = true
                }
            }
        }
    }
    
    @IBAction func deleteImage1ButtonTapped(_ sender: UIButton) {
        self.images.remove(at: 0)
        self.media_ids.remove(at: 0)
        refreshImages()
    }
    
    @IBAction func deleteImage2ButtonTapped(_ sender: UIButton) {
        self.images.remove(at: 1)
        self.media_ids.remove(at: 1)
        refreshImages()
    }
    
    @IBAction func deleteImage3ButtonTapped(_ sender: UIButton) {
        self.images.remove(at: 2)
        self.media_ids.remove(at: 2)
        refreshImages()
    }
    
    @IBAction func deleteImage4ButtonTapped(_ sender: UIButton) {
        self.images.remove(at: 3)
        self.media_ids.remove(at: 3)
        refreshImages()
    }
    
    func makeTootUrl(_ url: String) -> String {
        return "https://\(url)/api/v1/statuses".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func statusUrl(_ url : String, statusId : String) -> String {
        return "https://\(url)/api/v1/statuses/\(statusId)".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    func mediaUrl(_ url :String) -> String {
        return "https://\(url)/api/v1/media".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
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
