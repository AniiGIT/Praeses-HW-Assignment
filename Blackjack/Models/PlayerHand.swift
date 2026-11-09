//
//  PlayerHand.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

// The hand the player is betting on, splitting will cause several instances of these
struct PlayerHand: Equatable {
    var hand = Hand()
    var bet: Int
    var isDoubled = false
    var isStanding = false
    
    var cards: [Card] {
        hand.cards
    }
    
    var value: Int {
        hand.value
    }
}
