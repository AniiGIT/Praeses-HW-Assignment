//
//  GamePhase.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

enum GamePhase: Equatable {
    case betting // waiting for player to place bet
    case insuranceOffer // dealers shows an ace and offers insurance
    case playerTurn // player's turn
    case dealerTurn // dealer reveals the hole card and draws
    case roundOver // round ended
    case gameOver // round ended and player can no longer cover minimum bet
}
