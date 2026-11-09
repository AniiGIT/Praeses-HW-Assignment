//
//  RoundOutcome.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

enum HandOutcome: Equatable {
    case blackjack // Player hand = 21 (natural)
    case win  // Player hand > Dealer hand
    case push // Dealer hand = Player hand
    case loss // Dealer hand > Player hand
    case bust // Player hand > 21
}

struct HandResult: Equatable {
    let outcome: HandOutcome
    let bet: Int
    let payout: Int
    
    var net: Int {
        payout - bet
    }
}

struct RoundResult: Equatable {
    let handResults: [HandResult]
    let insuranceBet: Int
    let insurancePayout: Int
    let dealerHadBlackjack: Bool
    
    var net: Int {
        handResults.reduce(0) { $0 + $1.net } + insurancePayout - insuranceBet
    }
}
