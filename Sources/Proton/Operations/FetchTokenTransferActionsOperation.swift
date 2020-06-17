//
//  FetchTokenTransferActionsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class FetchTokenTransferActionsOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var tokenContract: TokenContract
    var tokenBalance: TokenBalance
    let limt = 100
    
    init(account: Account, tokenContract: TokenContract, chainProvider: ChainProvider,
         tokenBalance: TokenBalance) {
        
        self.account = account
        self.tokenContract = tokenContract
        self.chainProvider = chainProvider
        self.tokenBalance = tokenBalance
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.hyperionHistoryUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        
        struct TransferActionData: ABIDecodable {
            let from: Name
            let to: Name
            let amount: Double
            let symbol: String
            let memo: String
            let quantity: Asset
        }

        var req = API.V2.Hyperion.GetActions<TransferActionData>(self.account.name)
        req.filter = "\(self.tokenContract.contract.stringValue):transfer"
        req.transferSymbol = self.tokenContract.symbol.name
        req.limit = UInt(self.limt)

        do {

            let res = try client.sendSync(req).get()

            var tokenTranfsers = Set<TokenTransferAction>()

            for action in res.actions {

                let transferAction = TokenTransferAction(chainId: account.chainId, accountId: account.id,
                                                         tokenBalanceId: tokenBalance.id, tokenContractId: tokenContract.id,
                                                         name: "transfer", contract: tokenContract.contract,
                                                         trxId: String(action.trxId), date: action.timestamp.date,
                                                         sent: self.account.name.stringValue == action.act.data.from.stringValue ? true : false,
                                                         from: action.act.data.from,
                                                         to: action.act.data.to, quantity: action.act.data.quantity, memo: action.act.data.memo)
                
                tokenTranfsers.update(with: transferAction)

            }

            finish(retval: tokenTranfsers, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V2.Hyperion.GetActions<TransferActionABI>.path)\nERROR => \(error.localizedDescription)"))
        }
        
    }
    
}
