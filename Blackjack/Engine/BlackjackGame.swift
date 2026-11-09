//
//  BlackjackGame.swift
//  Blackjack
//
//  Created by Mark Brown
//

import Foundation

// The complete rules engine for Blackjack
// Round flow: betting -> (insuranceOffer?) -> playerTurn -> dealerTurn -> roundOver / gameOver

struct BlackjackGame {
    // MARK: State
    
    private(set) var rules: GameRules
    private(set) var shoe: Shoe
    private(set) var balance: Int
    private(set) var phase: GamePhase = .betting
    private(set) var playerHands: [PlayerHand] = []
    private(set) var activeHandIndex = 0
    private(set) var dealerHand = Hand()
    private(set) var isDealerHoleCardRevealed = false
    private(set) var insuranceBet = 0
    private(set) var lastResult: RoundResult?
    
    init(rules: GameRules = GameRules(), shoe: Shoe? = nil) {
        self.rules = rules
        self.shoe = shoe ?? Shoe(deckCount: rules.deckCount,reshuffleThreshold: rules.reshuffleThreshold)
        self.balance = rules.startingBalance
    }
    
    var activeHand: PlayerHand? {
        guard phase == .playerTurn, playerHands.indices.contains(activeHandIndex) else { return nil }
        return playerHands[activeHandIndex]
    }
    
    var dealerUpCard: Card? {
        dealerHand.cards.first
    }
    
    var dealerVisableCards: [Card] {
        isDealerHoleCardRevealed ? dealerHand.cards : Array(dealerHand.cards.prefix(1))
    }
    
    var dealerVisableValue: Int {
        Hand(cards: dealerVisableCards).value
    }
    
    var insuranceCost: Int {
        (playerHands.first?.bet ?? 0) / 2
    }
    
    var availableActions: Set<PlayerAction> {
        guard let hand = activeHand else { return [] }
        
        var actions: Set<PlayerAction> = [.hit, .stand]
        let hasTwoCards = hand.cards.count == 2
        let canCoverBet = balance >= hand.bet
        
        let doublingAllowed = !hand.hand.isFromSplit || rules.allowsDoubleAfterSplit
        
        if hasTwoCards && canCoverBet && doublingAllowed {
            actions.insert(.doubleDown)
        }
        
        let hasRoomToSplit = playerHands.count < rules.maximumHands
        let isSplittable = hand.hand.isSplittable(matchingTenValueCards: rules.splitsAnyTenValueCards)
        if isSplittable && canCoverBet && hasRoomToSplit {
            actions.insert(.split)
        }
        return actions
    }
    
    // MARK: Betting and Dealing
    mutating func startRound(bet: Int) throws {
        guard phase == .betting else {throw GameError.wrongPhase }
        try validate(bet: bet)
        
        if shoe.needsShuffle {
            shoe.shuffle()
        }
        
        clearTable()
        balance -= bet
        playerHands = [PlayerHand(bet: bet)]
        
        dealCardToPlayerHand(at: 0)
        dealCardToDealer()
        dealCardToPlayerHand(at: 0)
        dealCardToDealer()
        
        let insuranceIsPossible = rules.isInsuranceOffered && dealerUpCard?.rank == .ace && insuranceCost > 0 && balance >= insuranceCost
        
        if insuranceIsPossible {
            phase = .insuranceOffer
        } else {
            resolveOpeningBlackjacks()
        }
    }
    
    // MARK: Insurance
    
    mutating func takeInsurance() throws {
        guard phase == .insuranceOffer else { throw GameError.wrongPhase }
        
        insuranceBet = insuranceCost
        balance -= insuranceBet
        resolveOpeningBlackjacks()
    }
    
    mutating func declineInsurance() throws {
        guard phase == .insuranceOffer else { throw GameError.wrongPhase }
        
        resolveOpeningBlackjacks()
    }
    
    // MARK: Player's Turn
    
    mutating func perform(_ action: PlayerAction) throws {
        guard phase == .playerTurn else { throw GameError.wrongPhase }
        guard availableActions.contains(action) else { throw GameError.actionNotAllowed(action) }
        
        switch action {
            case .hit:
                dealCardToPlayerHand(at: activeHandIndex)
            case .stand:
                playerHands[activeHandIndex].isStanding = true
            case .doubleDown:
                doubleDownActiveHand()
            case .split:
                splitActiveHand()
        }
        advanceToNextUnfinishedHand()
    }
    
    // MARK: Dealer's Turn
    
    mutating func advanceDealerTurn() throws {
        guard phase == .dealerTurn else { throw GameError.wrongPhase }
        
        if !isDealerHoleCardRevealed {
            isDealerHoleCardRevealed = true
        } else if dealerMustHit {
            dealCardToDealer()
        } else {
            endRound()
        }
    }
    
    mutating func playDealerTurn() throws {
        guard phase == .dealerTurn else { throw GameError.wrongPhase }
        while phase == .dealerTurn {
            try advanceDealerTurn()
        }
    }
    
    // MARK: Between Rounds
    
    mutating func prepareNextRound() throws {
        guard phase == .roundOver else { throw GameError.wrongPhase }
        clearTable()
        phase = .betting
    }
    
    // Restores balance and a new shoe, passes in forcedOpeningCards from debug menu to control first cards dealt
    mutating func resetGame(rules newRules: GameRules? = nil, forcedOpeningCards: [Card] = []) {
        if let newRules = newRules {
            rules = newRules
        }
        
        if forcedOpeningCards.isEmpty{
            shoe = Shoe(
                deckCount: rules.deckCount,
                reshuffleThreshold: rules.reshuffleThreshold)
        } else {
            shoe = Shoe(
                deckCount: rules.deckCount,
                reshuffleThreshold: rules.reshuffleThreshold,
                forcedOpeningCards: forcedOpeningCards
            )
        }
        balance = rules.startingBalance
        clearTable()
        phase = .betting
    }
    
    // MARK: Private: validation
    
    private func validate(bet: Int) throws {
        let isWithinLimits = bet >= rules.minimumBet && bet <= rules.maximumBet
        let isValidIncrement = bet % rules.betIncrement == 0
        guard isWithinLimits && isValidIncrement else { throw GameError.invalidBet }
        guard bet <= balance else { throw GameError.insufficientChips}
    }
    
    // MARK: Private: dealing
    
    private mutating func dealCardToPlayerHand(at index: Int) {
        let card = shoe.draw()
        playerHands[index].hand.add(card)
    }
    
    private mutating func dealCardToDealer() {
        let card = shoe.draw()
        dealerHand.add(card)
    }
    
    private mutating func clearTable() {
        playerHands = []
        activeHandIndex = 0
        dealerHand = Hand()
        isDealerHoleCardRevealed = false
        insuranceBet = 0
        lastResult = nil
    }
    
    // MARK: Private: opening naturals
    
    private mutating func resolveOpeningBlackjacks() {
        if dealerHand.isBlackjack || playerHands[0].hand.isBlackjack {
            endRound()
        } else {
            phase = .playerTurn
        }
    }
    
    // MARK: Private: player actions
    
    private mutating func doubleDownActiveHand() {
        let index = activeHandIndex
        balance -= playerHands[index].bet
        playerHands[index].bet *= 2
        playerHands[index].isDoubled = true
        dealCardToPlayerHand(at: index)
        playerHands[index].isStanding = true
    }
    
    // Split player's active hand, replaces the original pair with 2 one card hands
    private mutating func splitActiveHand() {
        let index = activeHandIndex
        let original = playerHands[index]
        let pairCards = original.cards
        
        balance -= original.bet
        
        let firstHand = PlayerHand(hand: Hand(cards: [pairCards[0]], isFromSplit: true), bet: original.bet)
        let secondHand = PlayerHand(hand: Hand(cards: [pairCards[1]], isFromSplit: true), bet: original.bet)
        playerHands[index] = firstHand
        playerHands.insert(secondHand, at: index + 1)
    }
    
    // If there are no more actions a player can take on the hand
    private func isFinished(_ playerHand: PlayerHand) -> Bool {
        let hand = playerHand.hand
        let isSplitAceWithItsOneCard = rules.splitAcesReceiveOneCard && hand.isFromSplit && hand.cards.first?.rank == .ace && hand.cards.count >= 2
        
        return playerHand.isStanding || hand.isBust || hand.value == 21 || isSplitAceWithItsOneCard
    }
    
    private mutating func advanceToNextUnfinishedHand() {
        while activeHandIndex < playerHands.count {
            if playerHands[activeHandIndex].cards.count < 2 {
                dealCardToPlayerHand(at: activeHandIndex)
            }
            
            if !isFinished(playerHands[activeHandIndex]) {
                return
            }
            
            activeHandIndex += 1
        }
        beginDealerTurn()
    }
    
    // MARK: Private: dealer
    
    private var dealerMustHit: Bool {
        let value = dealerHand.value
        if value < 17 { return true }
        return value == 17 && dealerHand.isSoft && rules.dealerHitsSoft17
    }
    
    // If every player hand busted, dealer doesn't need to draw
    private mutating func beginDealerTurn() {
        let anyHandStillLive = playerHands.contains { !$0.hand.isBust }
        if anyHandStillLive {
            phase = .dealerTurn
        } else {
            endRound()
        }
    }
    
    // MARK: Private: ending round
    
    private mutating func endRound() {
        isDealerHoleCardRevealed = true
        
        var handResults: [HandResult] = []
        for playerHand in playerHands {
            let handOutcome = outcome(of: playerHand.hand)
            let payout = payoutAmount(for: handOutcome, bet: playerHand.bet)
            balance += payout
            handResults.append(HandResult(outcome: handOutcome, bet: playerHand.bet, payout: payout))
        }
        
        // Insurance pays 2:1 and stake gets returned
        var insurancePayout = 0
        if insuranceBet > 0 && dealerHand.isBlackjack {
            insurancePayout = insuranceBet * 3
            balance += insurancePayout
        }
        
        lastResult = RoundResult(
            handResults: handResults,
            insuranceBet: insuranceBet,
            insurancePayout: insurancePayout,
            dealerHadBlackjack: dealerHand.isBlackjack
        )
        phase = balance < rules.minimumBet ? .gameOver : .roundOver
    }
    
    private func outcome(of hand: Hand) -> HandOutcome {
        if hand.isBust { return .bust }
        
        let dealerHasBlackjack = dealerHand.isBlackjack
        if hand.isBlackjack {
            return dealerHasBlackjack ? .push : .blackjack
        }
        if dealerHasBlackjack { return .loss }
        if dealerHand.isBust { return .win }
        
        if hand.value > dealerHand.value { return .win }
        if hand.value < dealerHand.value { return .loss }
        return .push
    }
    
    private func payoutAmount(for outcome: HandOutcome, bet: Int) -> Int {
        switch outcome {
            case .blackjack: return bet + rules.blackjackWinnings(for: bet)
            case .win: return bet * 2
            case .push: return bet
            case .loss, .bust: return 0
        }
    }
}
