//
//  AssetService.swift
//  DynamicFilteringTest
//
//  Created by Kuu Miyazaki on 2018/03/18.
//  Copyright © 2018 Kuu Miyazaki. All rights reserved.
//

import UIKit
import CommonCrypto

let API_KEY = "Ooyala API Key"
let API_SECRET = "Ooyala API Secret"
let PCODE = String(API_KEY.prefix(API_KEY.count - 6))

struct Label {
    let id: String
    let name: String
    let path: String
}

class Asset {
    let pcode = PCODE
    let id: String
    let name: String
    let description: String
    let duration: Int
    let createdAt: Date
    var thumbnail: UIImage?
    
    init(id: String, name: String, description: String, duration: Int, createdAt: String) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.date(from: createdAt)!
    }
    
    func setThumbnail(_ url: String, _ completion: @escaping () -> ()) {
        let url = URL(string: url)
        AssetService.getImage(for: url, {[weak self] (image: UIImage?) -> Void in
            self?.thumbnail = image
            completion()
        })
    }
    
}

struct AssetService {
    static func getLabels(_ completion: @escaping ([Label]) ->Void) {
        get(path: "/v2/labels", params: [:], {(items: [[String: Any]]) -> Void in
            var labels = [Label]()
            for item in items {
                if let id = item["id"] as? String, let name = item["name"] as? String, let path = item["full_name"] as? String {
                    labels.append(Label(id: id, name: name, path: path))
                }
            }
            debugPrint("@@@@ labels.count = \(labels.count)")
            completion(labels)
        })
    }
    
    static func getAssets(for label: Label, _ completion: @escaping ([Asset]) ->Void) {
        get(path: "/v2/assets", params: ["where": "labels+INCLUDES+'\(label.name)'"], {(items: [[String: Any]]) -> Void in
            let data = items.filter{
                ($0["status"] as? String) == "live" && ($0["asset_type"] as? String) == "video"
            }
            var assets = [Asset]()
            var i = 0
            for item in data {
                if let id = item["embed_code"] as? String,
                    let name = item["name"] as? String,
                    let description = item["description"] as? String,
                    let duration = item["duration"] as? Int,
                    let createdAt = item["created_at"] as? String,
                    let thumbnailUrl = item["preview_image_url_ssl"] as? String {
                    
                    let asset = Asset(id: id, name: name, description: description, duration: duration, createdAt: createdAt)
                    asset.setThumbnail(thumbnailUrl, {
                        i += 1
                        if assets.count == i {
                            debugPrint("@@@@ assets.count = \(assets.count)")
                            completion(assets)                            
                        }
                    })
                    assets.append(asset)
                    
                }
            }
            if assets.count == 0 {
                debugPrint("@@@@ assets.count = \(assets.count)")
                completion(assets)
            }
        })
    }
}

private extension AssetService {
    static func mainThread(_ completion: @escaping () -> ()) {
        DispatchQueue.main.async {
            completion()
        }
    }
    
    static func sha256(_ str : String) -> String {
        let data = str.data(using: String.Encoding.utf8)!
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
        }
        return String(Data(bytes: hash).base64EncodedString().prefix(43))
    }
    
    static func serialize(queries: [String: String], delimiter: String) -> String {
        let params = queries.sorted(by: { $0.0 < $1.0 })
        var array = [String]()
        for (key, value) in params {
            array.append("\(key)=\(value)")
        }
        return array.joined(separator: delimiter)
    }
    
    static func sign(method: String, path: String, queries: [String: String], body: String) -> String {
        let plain = "\(API_SECRET)\(method)\(path)\(serialize(queries: queries, delimiter: ""))\(body)"
        let encrypted = sha256(plain).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        // debugPrint("@@@@ signature plain = \(plain)")
        // debugPrint("@@@@ signature encrypted = \(encrypted)")
        return encrypted
    }
    
    static func get(path: String, params: [String: String], _ completion: @escaping ([[String: Any]]) -> ()) {
        var queries = params
        if let expires = params["expires"] {
            queries["expires"] = expires
        } else {
            queries["expires"] = String(Int(Date().timeIntervalSince1970 + 3600))
        }
        queries["api_key"] = API_KEY
        queries["signature"] = sign(method: "GET", path: path, queries: queries, body: "")
        
        var components = URLComponents(string: "https://api.ooyala.com\(path)")!
        var items = [URLQueryItem]()
        for (key, value) in queries {
            items.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = items
        
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "\'", with: "%27")

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"
        
        debugPrint("@@@@ request url = \(urlRequest.url!)")
        
        URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data, error == nil else {
                debugPrint("@@@@ error = \(error.debugDescription)")
                mainThread({ completion([]) })
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
            
            guard let items = json?["items"] as? [[String: Any]] else {
                debugPrint("@@@@ response.message = \(String(describing: json?["message"]))")
                mainThread({ completion([]) })
                return
            }
            
            mainThread({completion(items)})
        }.resume()
    }
    
    static func getImage(for url: URL?, _ completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            guard let url = url else {
                mainThread {completion(nil)}
                return
            }
            let data = try? Data(contentsOf: url)
            mainThread({
                completion(UIImage(data: data!))
            })
        }
    }
}
