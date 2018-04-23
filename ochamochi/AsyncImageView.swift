//
//  AsyncImageView.swift
//  ochamochi
//

import UIKit

class AsyncImageView: UIImageView {
    let TIMEOUT_INTERVAL : TimeInterval = 60
    var _url: String? = nil
    
    func imageAsync(urlString: String) -> URLSessionDataTask? {
        var task : URLSessionDataTask? = nil
        _url = urlString
        if let imageUrl = URL(string: urlString) {
            let request = URLRequest(url: imageUrl, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: self.TIMEOUT_INTERVAL)
            task = URLSession.shared.dataTask(with: request) {
                (data, response, err) in
                if (err == nil) {
                    DispatchQueue.main.async {
                        if (self._url == urlString) {
                            self.image = UIImage(data: data!)
                        }
                    }
                }
            }
            task!.resume()
        }
        return task
    }
}
