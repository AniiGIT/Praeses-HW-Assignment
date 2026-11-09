//
//  GameView.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

struct GameView: View {
    let viewModel: GameViewModel
    
    @State private var showsDebugMenu = false
    
    private var game: BlackjackGame {
        viewModel.game
    }
    
    var body: some View{
        ZStack {
            Color(red: 0.05, green: 0.38, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                header
                dealerSection
                Spacer(minLength: 0)
                statusLine
                playerSection
                ControlsView(viewModel: viewModel)
            }
            .padding()
        }
        .sheet(isPresented: $showsDebugMenu) {
            DebugMenuView(viewModel: viewModel)
        }
        .alert("Something wen wrong", isPresented: errorIsPresented) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: Sections
    
    private var header: some View {
        HStack {
            // Long press the title to open the debug menu
            Text("Blackjack")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 1.5) {
                    showsDebugMenu = true
                }
            
            Spacer()
            
            Label("\(game.balance)", systemImage: "circle.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.yellow)
                .contentTransition(.numericText())
                .animation(.default, value: game.balance)
        }
    }
    
    private var dealerSection: some View {
        HandView(
            title: "Dealer",
            cards: game.dealerVisableCards,
            faceDownCardCount: viewModel.dealerHiddenCardCount,
            valueText: viewModel.dealerHandText
        )
    }
    
    private var statusLine: some View {
        Text(viewModel.statusMessage)
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
    }
    
    @ViewBuilder
    private var playerSection: some View {
        if game.playerHands.isEmpty {
            HandView(title: "You", cards: [], valueText: "")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(game.playerHands.enumerated()), id: \.offset) {
                        index, playerHand in  
                        HandView(
                            title: game.playerHands.count > 1 ? "Hand \(index + 1)" : "You",
                            cards: playerHand.cards,
                            valueText: playerHand.hand.displayText,
                            bet: playerHand.bet,
                            isActive: game.phase == .playerTurn && index == game.activeHandIndex,
                            result: result(forHandAt: index)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: Helpers
    
    private func result(forHandAt index: Int) -> HandResult? {
        guard let results = game.lastResult?.handResults,
              results.indices.contains(index) else { return nil }
        return results[index]
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in if !isPresented { viewModel.dismissError() }}
        )
    }
}

#Preview {
    GameView(viewModel: GameViewModel())
}
