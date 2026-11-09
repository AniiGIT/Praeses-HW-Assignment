//
//  Hand.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

// Set of cards and all paths that can occur from said hand
struct Hand: Equatable {
    private(set) var cards: [Card]
    
    // Check for hands created by splitting (not natural blackjack)
    let isFromSplit: Bool
    
    init(cards: [Card] = [], isFromSplit: Bool = false) {
        self.cards = cards
        self.isFromSplit = isFromSplit
    }
    
    mutating func add(_ card: Card) {
        cards.append(card)
    }
    
    // Total where every ace has a value of 1
    private var hardTotal: Int {
        cards.reduce(0) {$0 + $1.rank.baseValue}
    }
    
    private var hasAce: Bool {
        cards.contains {$0.rank == .ace}
    }
    
    // This is the best total, ace will counts as 11 if it doesn't bust the hand
    var value: Int {
        isSoft ? hardTotal + 10 : hardTotal
    }
    
    // True when ace counts as 11 and not 1
    var isSoft: Bool {
        hasAce && hardTotal + 10 <= 21
    }
    
    var isBust: Bool {
        value > 21
    }
    
    // Ace + 10 value card is blackjack, must not be from a split
    var isBlackjack: Bool {
        !isFromSplit && cards.count == 2 && value == 21
    }
    
    // Do two cards in hand have the same rank?
    var isPair: Bool {
        cards.count == 2 && cards[0].rank == cards[1].rank
    }
    
    func isSplittable(matchingTenValueCards: Bool) -> Bool {
        guard cards.count == 2 else { return false }
        if isPair {return true }
        return matchingTenValueCards && cards[0].rank.isTenValue && cards[1].rank.isTenValue
    }
 }

