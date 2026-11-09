//
//  Card.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

enum Suit: CaseIterable {
    case spades, diamonds, hearts, clubs
    
    var symbol: String {
        switch self {
        case .spades: return "♠️"
        case .diamonds: return "♦️"
        case .hearts: return "♥️"
        case .clubs: return "♣️"
        }
    }
        
    var isRed: Bool {
        self == .diamonds || self == .hearts
    }
    
    var isBlack: Bool {
        self == .spades || self == .clubs
    }
}

enum Rank: Int, CaseIterable {
    case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    
    var baseValue: Int {
        switch self {
            case .jack, .queen, .king: return 10
            case .ace: return 1
            default: return rawValue
        }
    }
    
    var isTenValue: Bool {
        baseValue == 10
    }
    
    var label: String {
        switch self {
            case .jack: return "J"
            case .queen: return "Q"
            case .king: return "K"
            case .ace: return "A"
            default: return String(rawValue)
        }
    }
}

struct Card: Equatable, Hashable, CustomStringConvertible {
    let rank: Rank
    let suit: Suit
    
    var description: String {
        "\(rank.label)\(suit.symbol)"
    }
    
    static var fullDeck: [Card] {
        Suit.allCases.flatMap{ suit in Rank.allCases.map { rank in Card(rank: rank, suit: suit)}
        }
    }
}
