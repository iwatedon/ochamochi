//
//  AttachmentDetailViewController.swift
//  ochamochi
//
//

import UIKit

class AttachmentDetailViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var closeButton: UIButton?
    
    var imageView: UIImageView? = nil
    var url: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView?.delegate = self
        
        imageView = UIImageView(frame: CGRect(x:0, y:0,  width: scrollView!.frame.size.width, height: scrollView!.frame.size.height))
        imageView?.contentMode = UIViewContentMode.scaleAspectFit
        scrollView?.addSubview(imageView!)

        DispatchQueue.global().async {
            if let imageUrl = URL(string: self.url!) {
                let request = URLRequest(url: imageUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
                let task = URLSession.shared.dataTask(with: request) {
                    (data, response, err) in
                    if (err == nil) {
                        DispatchQueue.main.async {
                            self.imageView?.image = UIImage(data: data!)
                        }
                    }
                }
                task.resume()
            }
        }
        
        self.scrollView?.bringSubview(toFront: closeButton!)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBAction func closeButtonTapped(_ sender : UIButton?) {
        dismiss(animated: true, completion: {})
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
