//
//  CheckHyperionHistoryResponseTimeOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//


import Foundation
import WebOperations
import EOSIO

class CheckHyperionHistoryResponseTimeOperation: BaseOperation {
    
    var historyUrl: String
    var path: String
    
    init(historyUrl: String, path: String) {
        self.historyUrl = historyUrl
        self.path = path
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: "\(historyUrl)\(path)") else {
            self.finish(retval: URLRepsonseTimeCheck(url: historyUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
            return
        }
        
        let start = Date()
        
        let urlRequest = URLRequest(url: url, timeoutInterval: 5.0)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let _ = error {
                self.finish(retval: URLRepsonseTimeCheck(url: self.historyUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
            }
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.finish(retval: URLRepsonseTimeCheck(url: self.historyUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
                return
            }
            
            var end = Date().timeIntervalSince(start)
            var chainHeadBlock: BlockNum?
            var esHeadBlock: BlockNum?
            var blockDiff: BlockNum?
            
            do {
                
                let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                if let health = res["health"] as? [[String: Any]] {
                    for service in health {
                        if let s = service["service"] as? String, let serviceData = service["service_data"] as? [String: Any] {
                            if s == "NodeosRPC" {
                                chainHeadBlock = serviceData["head_block_num"] as? BlockNum
                            } else if s == "Elasticsearch" {
                                esHeadBlock = serviceData["last_indexed_block"] as? BlockNum
                            }
                        }
                    }
                }
                
                if let chainHeadBlock = chainHeadBlock, let esHeadBlock = esHeadBlock {
                    blockDiff = chainHeadBlock - esHeadBlock
                }

            } catch {
                print(error)
            }
            
            if let blockDiff = blockDiff, blockDiff > 30 {
                end = Date.distantPast.timeIntervalSinceNow * -1
            }
            
            self.finish(retval: URLRepsonseTimeCheck(url: self.historyUrl, time: end), error: nil)
            
        }
        task.resume()
        
    }
    
}
