//
//  PlayerAction.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

enum PlayerAction: Hashable, CaseIterable {
    case hit
    case stand
    case doubleDown
    case split
}
