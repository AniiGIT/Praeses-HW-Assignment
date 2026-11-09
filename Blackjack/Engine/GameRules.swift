//
//  GameRules.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

// All changeable rules and numbers
// Defaults follow the official Bicycle rules

struct GameRules: Equatable {
    
    // MARK: Balance and betting
    
    var startingBalance = 1000
    var minimumBet = 10
    var maximumBet = 500
    var betIncrement = 10
    
    // MARK: Shoe
    
    var deckCount = 6
    var reshuffleThreshold = 0.75
    
    // MARK: Dealer
    
    var dealerHitsSoft17 = false
    
    // MARK: Player options
    
    var isInsuranceOffered = true
    var allowsDoubleAfterSplit = true
    var splitsAnyTenValueCards = true
    
    // Total number of hands a player can have after splitting
    var maximumHands = 4
    
    var splitAcesReceiveOneCard = true
    
    // MARK: Payouts
    
    var blackjackPayoutNumerator = 3
    var blackjackPayoutDenominator = 2
    
    func blackjackWinnings(for bet: Int) -> Int {
        bet * blackjackPayoutNumerator / blackjackPayoutDenominator
    }
}
