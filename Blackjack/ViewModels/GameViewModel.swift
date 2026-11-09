//
//  GameViewModel.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {
    
    // MARK: State
    
    private(set) var game: BlackjackGame
    private(set) var pendingBet: Int
    private(set) var errorMessage: String?
    
    @ObservationIgnored private var dealerTask: Task<Void, Never>?
    @ObservationIgnored private let dealerStepDelay: Duration
    
    init(game: BlackjackGame = BlackjackGame(), dealerStepDelay: Duration = .milliseconds(800)) {
        self.game = game
        self.pendingBet = game.rules.minimumBet
        self.dealerStepDelay = dealerStepDelay
    }
    
    // MARK: Betting
    var chipDenominations: [Int] {
        [1, 5, 10].map { $0 * game.rules.betIncrement }
    }
    
    var maxSelectableBet: Int {
        let rules = game.rules
        let affordable = game.balance / rules.betIncrement * rules.betIncrement
        return min(rules.maximumBet, affordable)
    }
    
    var canDeal: Bool {
        game.phase == .betting && pendingBet >= game.rules.minimumBet && pendingBet <= maxSelectableBet
    }
    
    func addToBet(_ amount: Int) {
        guard game.phase == .betting else { return }
        pendingBet += amount
        constrainBet()
    }
    
    func resetBet() {
        pendingBet = game.rules.minimumBet
    }
    
    // MARK: Intents
    
    func deal() {
        attempt { try game.startRound(bet: pendingBet) }
    }
    
    func perform(_ action: PlayerAction) {
        attempt { try game.perform(action) }
        playDealerTurnIfNeeded()
    }
    
    func takeInsurance() {
        attempt { try game.takeInsurance() }
    }
    
    func declineInsurance() {
        attempt {try game.declineInsurance() }
    }
    
    func nextRound() {
        attempt { try game.prepareNextRound() }
        constrainBet()
    }
    
    func resetGame() {
        dealerTask?.cancel()
        game.resetGame()
        resetBet()
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    // MARK: Debug Menu
    
    func validationMessage(for rules: GameRules) -> String? {
        if rules.minimumBet <= 0 { return "Minimum be must be above 0" }
        if rules.betIncrement <= 0 { return "Bet increment must be above 0"}
        if rules.minimumBet % rules.betIncrement != 0 { return "Minimum bet must be a a multiple of the increment" }
        if rules.maximumBet < rules.minimumBet { return "Maxmium bet must be at least the minimum bet" }
        if rules.startingBalance < rules.minimumBet { return "Starting balance must cover the minimum bet" }
        if rules.deckCount < 1 { return "The shoe needs atleast one deck" }
        if rules.maximumHands < 2 { return "Maximum hands must be at least 2" }
        if rules.blackjackPayoutNumerator <= 0 || rules.blackjackPayoutDenominator <= 0 {
            return "Blackjack payout values must be above 0"
        }
        return nil
    }
    
    // Resetart game with new rules forcedOpeningCards are dealt first
    func applyDebugSettings(rules: GameRules, forcedOpeningCards: [Card]) {
        guard validationMessage(for: rules) == nil else { return }
        dealerTask?.cancel()
        game.resetGame(rules: rules, forcedOpeningCards: forcedOpeningCards)
        resetBet()
    }
    
    // MARK: Text for views
    
    var dealerHiddenCardCount: Int {
        game.dealerHand.cards.count - game.dealerVisableCards.count
    }
    
    var dealerHandText: String {
        Hand(cards: game.dealerVisableCards).displayText
    }
    
    var statusMessage: String {
        switch game.phase {
            case .betting:
                return "Place your bet"
            case .insuranceOffer:
                return "Dealer has an ace, insurance costs \(game.insuranceCost)"
            case .playerTurn:
                return "Your turn"
            case .dealerTurn:
                return "Dealer's turn"
            case .roundOver, .gameOver:
                return resultMessage ?? ""
        }
    }
    
    private var resultMessage: String? {
        guard let result = game.lastResult else { return nil }
        
        var parts: [String] = []
        if result.dealerHadBlackjack {
            parts.append("Dealer has blackjack")
        }
        
        if result.net > 0 {
            parts.append("You won \(result.net) chips")
        } else if result.net < 0 {
            parts.append("You lost \(-result.net) chips")
        } else {
            parts.append("No chips won or lost")
        }
        
        if result.insuranceBet > 0 {
            parts.append(result.insurancePayout > 0 ? "Insurance paid out" : "Insurance lost")
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: Private
    
    private func constrainBet() {
        pendingBet = max(game.rules.minimumBet, min(pendingBet, maxSelectableBet))
    }
    
    private func attempt(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = (error as? GameError)?.userMessage ?? error.localizedDescription
        }
    }
    
    private func playDealerTurnIfNeeded() {
        guard game.phase == .dealerTurn else { return }
        
        dealerTask?.cancel()
        dealerTask = Task { [weak self] in
            while let self, self.game.phase == .dealerTurn {
                try? await Task.sleep(for: self.dealerStepDelay)
                guard !Task.isCancelled else { return }
                self.attempt { try self.game.advanceDealerTurn() }
            }
        }
    }
}

extension GameError {
    var userMessage: String {
        switch self {
        case .wrongPhase: return "That is not possible right now"
        case .invalidBet: return "That bet is not allowed"
        case .insufficientChips: return "Not enough chips in balance"
        case .actionNotAllowed: return "Unable to do that"
        }
    }
}
