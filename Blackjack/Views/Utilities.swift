//
//  Presentation.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

extension Hand {
    var displayText: String {
        guard !cards.isEmpty else { return "" }
        if isBust { return "Bust (\(value))" }
        if isBlackjack { return "Blackjack!" }
        if isSoft { return "Soft \(value)" }
        return "\(value)"
    }
}

extension HandResult {
    var summary: String {
        switch outcome {
        case .blackjack: return "Blackjack +\(net)"
        case .win: return "Win +\(net)"
        case .push: return "Push"
        case .loss: return "Lost -\(-net)"
        case .bust: return "Bust -\(-net)"
        }
    }
    
    var color: Color {
        switch outcome {
        case .blackjack, .win: return .green
        case .push: return .gray
        case .loss, .bust: return .red
        }
    }
}
