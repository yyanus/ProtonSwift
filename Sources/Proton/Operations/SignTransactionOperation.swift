//
//  SignTransactionOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class SignTransactionOperation: BaseOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var actions: [Action]
    var privateKey: PrivateKey
    
    init(account: Account, chainProvider: ChainProvider, actions: [Action], privateKey: PrivateKey) {
        self.account = account
        self.chainProvider = chainProvider
        self.actions = actions
        self.privateKey = privateKey
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }
        
        if self.actions.count == 0 {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => There should be 1 or more actions"))
            return
        }
        
        do {
            
            let client = Client(address: url)
            let info = try client.sendSync(API.V1.Chain.GetInfo()).get()
            
            let expiration = info.headBlockTime.addingTimeInterval(60)
            let header = TransactionHeader(expiration: TimePointSec(expiration),
                                           refBlockId: info.lastIrreversibleBlockId)
            
            let transaction = Transaction(header, actions: self.actions)
            let signature = try self.privateKey.sign(transaction, using: info.chainId)
            
            let signedTransaction = SignedTransaction(transaction, signatures: [signature])
            
            self.finish(retval: signedTransaction, error: nil)
            
        } catch {
            self.finish(retval: nil, error: ProtonError.chain("MESSAGE => Issue signing transaciton\nRPC => \(API.V1.Chain.GetInfo.path)\nERROR => \(error.localizedDescription)"))
        }
        
    }
    
}
