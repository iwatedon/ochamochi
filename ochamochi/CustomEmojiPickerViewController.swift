//
//  CustomEmojiPickerViewController.swift
//  ochamochi
//
//  Created by さとうおさむ on 2018/10/25.
//

import UIKit
import OAuthSwift

class CustomEmojiPickerViewController: UIViewController {

    var emojis : [Emoji] = []
    var emojiImages : [String:UIImage] = [:]
    
    weak var previousController : MakeTootViewController?
    
    @IBOutlet var collectionView : UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.register(UINib(nibName: "CustomEmojiPickerCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CollectionViewCell")
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        loadEmojis()
        // Do any additional setup after loading the view.
    }
    
    func loadEmojis() {
        if let currentAccount = MastodonUtil.getCurrentAccount() {
            if let currentInstance = MastodonUtil.getCurrentInstance() {
                let oauthswift = OAuth2Swift(consumerKey: currentInstance.clientId, consumerSecret: currentInstance.clientSecret, authorizeUrl: "", responseType: "")
                oauthswift.client.credential.oauthToken = currentAccount.accessToken
                let _  = oauthswift.client.get(customEmojisUrl(currentInstance.url)) { result in
                    switch result {
                    case .success(let response):
                        do {
                            let dataString = response.string
                            let json = try JSONSerialization.jsonObject(with: dataString!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.allowFragments)
                            let emojis_json = json as! [Any]
                            emojis_json.forEach({ tmp in
                                let emoji = Emoji()
                                let emoji_json = tmp as! [String:Any]
                                emoji.shortcode = emoji_json["shortcode"] as! String
                                emoji.staticUrl = emoji_json["static_url"] as! String
                                emoji.url = emoji_json["url"] as! String
                                self.emojis.append(emoji)
                                
                                // read emoji image
                                DispatchQueue.global().async {
                                    if let imageUrl = URL(string: emoji.url!) {
                                        let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                                        let task = URLSession.shared.dataTask(with: request) {
                                            (data, response, err) in
                                            if (err == nil) {
                                                let image = UIImage(data: data!)!.resize(size: CGSize(width:32, height:32))
                                                self.emojiImages[emoji.shortcode!] = image!
                                            }
                                        }
                                        task.resume()
                                    }
                                }
                            })
                        } catch {
                            print(error)
                        }
                        DispatchQueue.main.async {
                            self.collectionView?.reloadData()
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func customEmojisUrl(_ url : String) -> String {
        return "https://\(url)/api/v1/custom_emojis"
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CustomEmojiPickerViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 32.0, height: 32.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let controller = previousController {
            let insertString = " :" + emojis[indexPath.row].shortcode! + ": "
            if let range = controller.textView?.selectedTextRange {
                controller.textView?.replace(range, withText: insertString)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CustomEmojiPickerCollectionViewCell
        
        let url = emojis[indexPath.row].url
        let shortcode = emojis[indexPath.row].shortcode
        
        // read emoji image
        DispatchQueue.global().async {
            if let imageUrl = URL(string: url!) {
                let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, err) in
                    if (err == nil) {
                        DispatchQueue.main.async {
                            cell.imageView!.image = self.emojiImages[shortcode!]
                        }
                    }
                }
                task.resume()
            }
        }
        return cell
    }
}
