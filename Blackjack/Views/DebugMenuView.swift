//
//  Untitled.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

struct DebugMenuView: View {
    let viewModel: GameViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var rules: GameRules
    @State private var forcedCards: [ForcedCard] = []
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        _rules = State(initialValue: viewModel.game.rules)
    }
    
    private var validationMessage: String? {
        viewModel.validationMessage(for: rules)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                balanceAndBettingSection
                shoeSection
                dealerSection
                playerOptionsSection
                payoutSection
                forcedCardsSection
                applySection
                stateSection
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Defaults") {
                        rules = GameRules()
                        forcedCards = []
                    }
                }
            }
            
        }
        
    }
    
    
    // MARK: Rule Sections
    
    private var balanceAndBettingSection: some View {
        Section("Balance and Betting") {
            LabeledContent("Starting Balance") {
                TextField("Chips", value: $rules.startingBalance, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            Stepper("Minimum bet: \(rules.minimumBet)", value: $rules.minimumBet, in: 1...1_000, step: 5)
            Stepper("Maximum bet: \(rules.maximumBet)", value: $rules.maximumBet, in: 1...10_000, step: 50)
            Stepper("Bet increment: \(rules.betIncrement)", value: $rules.betIncrement, in: 1...100)
        }
    }
    
    private var shoeSection: some View {
        Section("Shoe") {
            Stepper("Decks: \(rules.deckCount)", value: $rules.deckCount, in: 1...8)
            VStack(alignment: .leading) {
                Text("Reshuffle after: \(Int((rules.reshuffleThreshold * 100).rounded()))% dealt")
                Slider(value: $rules.reshuffleThreshold, in: 0.1...0.95, step: 0.05)
            }
        }
    }
    
    private var dealerSection: some View {
        Section("Dealer") {
            Toggle("Dealer hits soft 17", isOn: $rules.dealerHitsSoft17)
        }
    }
    
    private var playerOptionsSection: some View {
        Section("Player options") {
            Toggle("Insurance offered", isOn: $rules.isInsuranceOffered)
            Toggle("Double after split", isOn: $rules.allowsDoubleAfterSplit)
            Toggle("Split aces get one card", isOn: $rules.splitAcesReceiveOneCard)
            Toggle("Split any two ten-value cards", isOn: $rules.splitsAnyTenValueCards)
            Stepper("Maximum hands: \(rules.maximumHands)", value: $rules.maximumHands)
        }
    }
    
    private var payoutSection: some View {
        Section {
            Stepper("Numerator: \(rules.blackjackPayoutNumerator)", value: $rules.blackjackPayoutNumerator)
            Stepper("Denominator: \(rules.blackjackPayoutDenominator)", value: $rules.blackjackPayoutDenominator)
        } header: {
            Text("Blackjack payout")
        } footer: {
            Text("Blackjack pays \(rules.blackjackPayoutNumerator):\(rules.blackjackPayoutDenominator)")
        }
    }
    
    // MARK: Forced Cards
    
    private var forcedCardsSection: some View {
        Section {
            ForEach($forcedCards) { $forced in
                HStack {
                    Text(dealLabel(for: forced))
                    Spacer()
                    Picker("Rank", selection: $forced.rank) {
                        ForEach(Rank.allCases, id: \.self) { rank in
                            Text(rank.label).tag(rank)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .onDelete{ forcedCards.remove(atOffsets: $0) }
            
            Button("Add Card") { forcedCards.append(ForcedCard()) }
            
            Menu("Load Preset") {
                ForEach(Self.presets) { preset in
                    Button(preset.name) {
                        forcedCards = preset.cards.map { ForcedCard(rank: $0.rank, suit: $0.suit) }
                    }
                }
            }
        } header: {
            Text("Forced opening cards")
        } footer: {
            Text("Dealt in order after you apply: player, dealer up card, player, dealer hole card, then draws. Swipe on a row to delete it, cards after these are random")
        }
    }
    
    private func dealLabel(for forced: ForcedCard) -> String {
        let position = forcedCards.firstIndex(where: { $0.id == forced.id }) ?? 0
        switch position {
            case 0: return "Player card 1"
            case 1: return "Dealer up card"
            case 2: return "Player card 2"
            case 3: return "Dealer hole card"
            default: return "Next draw \(position - 3)"
        }
    }
    
    // MARK: Apply and State
    
    private var applySection: some View {
        Section {
            Button("Apply and Restart Game") {
                viewModel.applyDebugSettings(rules: rules, forcedOpeningCards: forcedCards.map(\.card))
                dismiss()
            }
            .disabled(validationMessage != nil)
        } footer: {
            if let validationMessage {
                Text(validationMessage).foregroundStyle(.red)
            } else {
                Text("Restarts with a fresh shoe and the balance above")
            }
        }
    }
    
    private var stateSection: some View {
        Section("Current State") {
            LabeledContent("Chips", value: "\(viewModel.game.balance)")
            LabeledContent("Phase", value: String(describing: viewModel.game.phase))
            LabeledContent("Cards left in shoe", value: "\(viewModel.game.shoe.remainingCount)")
        }
    }
    
    // MARK: Presets
    
    private struct Preset: Identifiable {
        let name: String
        let cards: [Card]
        var id: String { name }
    }
    
    private static func makeCard(_ rank: Rank, _ suit: Suit = .spades) -> Card {
        Card(rank: rank, suit: suit)
    }
    
    private static let presets: [Preset] = [
        Preset(name: "Player blackjack", cards: [makeCard(.ace), makeCard(.six, .clubs), makeCard(.king, .clubs), makeCard(.nine, .hearts)]),
        Preset(name: "Dealer ace up, no blackjack", cards: [makeCard(.ten), makeCard(.ace, .hearts), makeCard(.two, .diamonds), makeCard(.four, .hearts)]),
        Preset(name: "Dealer Blackjack", cards: [makeCard(.ten), makeCard(.ace, .hearts), makeCard(.eight, .spades), makeCard(.king, .hearts)]),
        Preset(name: "Pair of Sevens (split)", cards: [makeCard(.seven), makeCard(.three, .clubs), makeCard(.seven, .hearts), makeCard(.jack, .diamonds)]),
        Preset(name: "Pair of Aces (split)", cards: [makeCard(.ace), makeCard(.five, .diamonds), makeCard(.ace, .clubs), makeCard(.ten, .diamonds)]),
        Preset(name: "Jack and King (split)", cards: [makeCard(.jack), makeCard(.three, .hearts), makeCard(.king, .hearts), makeCard(.ten, .diamonds)]),
        Preset(name: "Eleven vs Six (double down)", cards: [makeCard(.five), makeCard(.six, .spades), makeCard(.six, .hearts), makeCard(.ten, .diamonds)])
    ]
 }

private struct ForcedCard: Identifiable {
    let id = UUID()
    var rank: Rank
    var suit: Suit
    
    init(rank: Rank = .ace, suit: Suit = .spades) {
        self.rank = rank
        self.suit = suit
    }
    
    var card: Card {
        Card(rank: rank, suit: suit)
    }
}
