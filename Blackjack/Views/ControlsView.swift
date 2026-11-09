//
//  ControlsView.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

struct ControlsView: View {
    let viewModel: GameViewModel
    
    var body: some View {
        Group {
            switch viewModel.game.phase {
            case .betting:
                BettingControls(viewModel: viewModel)
            case .insuranceOffer:
                InsuranceControls(viewModel: viewModel)
            case .playerTurn:
                PlayerActionControls(viewModel: viewModel)
            case .dealerTurn:
                ProgressView()
                    .tint(.white)
            case .roundOver:
                Button("Next Round") { viewModel.nextRound() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            case .gameOver:
                Button("New Game") { viewModel.resetGame() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110)
    }
}

private struct BettingControls: View {
    let viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Bet: \(viewModel.pendingBet)")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            HStack(spacing: 10) {
                ForEach(viewModel.chipDenominations, id: \.self) { amount in
                    Button("+\(amount)") { viewModel.addToBet(amount) }
                }
                Button("Clear") { viewModel.resetBet() }
            }
            .buttonStyle(.bordered)
            .tint(.white)
            
            Button("Deal") { viewModel.deal() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canDeal)
        }
    }
}

private struct InsuranceControls: View {
    let viewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Take Insurance (\(viewModel.game.insuranceCost))") {
                viewModel.takeInsurance() }
            .buttonStyle(.borderedProminent)
            
            Button("Decline Insurance") { viewModel.declineInsurance() }
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .controlSize(.large)
    }
}

private struct PlayerActionControls: View {
    let viewModel: GameViewModel
    
    private var availableActions: Set<PlayerAction> {
        viewModel.game.availableActions
    }
    
    var body: some View {
        HStack(spacing: 10) {
            actionButton("Hit", action: .hit)
            actionButton("Stand", action: .stand)
            actionButton("Double", action: .doubleDown)
            actionButton("Split", action: .split)
        }
        .controlSize(.large)
    }
    
    private func actionButton( _ title: String, action: PlayerAction) -> some View {
        Button(title) { viewModel.perform(action) }
            .buttonStyle(.borderedProminent)
            .disabled(!availableActions.contains(action))
    }
}
