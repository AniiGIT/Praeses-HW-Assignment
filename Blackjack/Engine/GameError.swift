//
//  GameError.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

enum GameError: Error, Equatable {
    case wrongPhase // request is not valid in current phase of game
    case invalidBet // bet is outside table limits or not a multiple of bet increment
    case insufficientChips // player cannot cover bet
    case actionNotAllowed(PlayerAction) // action is not allowed on player's hand
}
