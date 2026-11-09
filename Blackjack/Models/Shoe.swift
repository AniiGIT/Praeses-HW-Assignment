//
//  Shoe.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

// Dealing shoe: one or more decks shuffled together (deck count can be changed)

struct Shoe {
    private(set) var cards: [Card]
    let deckCount: Int
    private let reshuffleThreshold: Int
    
    
    // Parameters:
    //// - deckCount: Numer of decks in the shoe
    //// - reshuffleThreshold: Fraction of the shoe dealt before it is reshuffled between rounds
    init(deckCount: Int, reshuffleThreshold: Double = 0.75) {
        precondition(deckCount > 0, "Shoe needs atleast one deck")
        let constrainReshuffleThreshold = min(max(reshuffleThreshold, 0.1), 0.95)
        self.deckCount = deckCount
        self.reshuffleThreshold = Int(Double(deckCount * 52) * (1 - constrainReshuffleThreshold))
        self.cards = Shoe.shuffledCards(deckCount: deckCount)
    }
    
    // Fixed, never reshuffled shoe
    init(stackedCards: [Card]) {
        self.deckCount = 0
        self.reshuffleThreshold = 0
        self.cards = Array(stackedCards.reversed())
    }
    
    // Normal shuffled shoe where the first cards are forced (using the dbug menu)
    init(deckCount: Int, reshuffleThreshold: Double = 0.75, forcedOpeningCards: [Card]) {
        self.init(deckCount: deckCount, reshuffleThreshold: reshuffleThreshold)
        for card in forcedOpeningCards {
            if let index = cards.firstIndex(of: card) {
                cards.remove(at: index)
            }
        }
        cards.append(contentsOf: forcedOpeningCards.reversed())
    }
    
    var remainingCount: Int {
        cards.count
    }
    
    // True once cut point has been passed, checked between rounds
    var needsShuffle: Bool {
        deckCount > 0 && cards.count <= reshuffleThreshold
    }
    
    // Rebuilds the shoe and shuffles it
    mutating func shuffle() {
        guard deckCount > 0 else { return }
        cards = Shoe.shuffledCards(deckCount: deckCount)
    }
    
    mutating func draw() -> Card {
        if cards.isEmpty {
            shuffle()
        }
        
        guard let card = cards.popLast() else {
            preconditionFailure("Shoe ran out of cards")
        }
        return card
    }
    
    private static func shuffledCards(deckCount: Int) -> [Card] {
        (0..<deckCount).flatMap { _ in Card.fullDeck }.shuffled()
    }
}
