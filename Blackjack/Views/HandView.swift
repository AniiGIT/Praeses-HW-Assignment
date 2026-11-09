//
//  HandView.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

struct HandView: View {
    let title: String
    let cards: [Card]
    var faceDownCardCount = 0
    let valueText: String
    var bet: Int?
    var isActive = false
    var result: HandResult?
    
    var body: some View {
        VStack(spacing: 6) {
            header
            cardRow
            footer
        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 4)
            .fill(Color.black.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(isActive ? Color.yellow : Color.clear, lineWidth: 3))
        .animation(.default, value: isActive)
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            
            if let bet {
                Text("Bet \(bet)")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue.opacity(0.5)))
            }
        }
        .foregroundStyle(.white)
    }
    
    @ViewBuilder
    private var cardRow: some View {
        if cards.isEmpty && faceDownCardCount == 0 {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .frame(width: CardView.size.width, height: CardView.size.height)
        } else {
            HStack(spacing: -24) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    CardView(card: card)
                    .transition(.scale.combined(with: .opacity))
                }
                ForEach(0..<faceDownCardCount, id: \.self) { _ in
                    CardView(card: nil)
                }
            }
            .animation(.spring(duration: 0.35), value: cards.count + faceDownCardCount)
        }
    }
    
    private var footer: some View {
        VStack(spacing: 2) {
            Text(valueText.isEmpty ? " " : valueText)
                .font(.headline)
                .foregroundStyle(.white)
            Text(result?.summary ?? " ")
                .font(.caption.weight(.bold))
                .foregroundStyle(result?.color ?? .clear)
        }
    }
}


#Preview {
    HandView(
        title: "You",
        cards: [Card(rank: .ace, suit: .hearts), Card(rank: .seven, suit: .diamonds)],
        valueText: "Soft 13",
        bet: 100,
        isActive: false,
    )
    .padding()
    .background(Color.green)
}
