//
//  FetchKeyAccountsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import EOSIO
import WebOperations

class FetchKeyAccountsOperation: BaseOperation {
    
    var publicKey: String
    var chainProvider: ChainProvider
    
    init(publicKey: String, chainProvider: ChainProvider) {
        self.publicKey = publicKey
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.hyperionHistoryUrl) else {
            self.finish(retval: nil, error: ProtonError.error("Missing chainProvider url"))
            return
        }
        
        guard let publicKey = PublicKey(publicKey) else {
            self.finish(retval: nil, error: ProtonError.error("Unable to parse public key"))
            return
        }

        let client = Client(address: url)
        let req = API.V2.Hyperion.GetKeyAccounts(publicKey)

        do {

            let res = try client.sendSync(req).get()

            var accountNames = Set<String>()

            for accountName in res.accountNames {

                if !accountName.stringValue.contains(".") {
                    accountNames.update(with: accountName.stringValue)
                }

            }
            
            if accountNames.count > 0 {
                self.finish(retval: accountNames, error: nil)
            } else {
                self.finish(retval: nil, error: ProtonError.history("RPC => \(API.V2.Hyperion.GetTokens.path) No accounts found for key: \(self.publicKey)"))
            }

            finish(retval: accountNames, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V2.Hyperion.GetTokens.path)\nERROR => \(error.localizedDescription)"))
        }

    }
    
}
