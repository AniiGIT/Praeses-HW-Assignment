//
//  CardView.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

struct CardView: View {
    let card: Card?
    
    static let size = CGSize(width: 54, height: 78)
    
    var body: some View {
        Group {
            if let card {
                face(of: card)
            } else {
                back
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private func face(of card: Card) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.white)
            RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1)
            VStack(spacing: 2) {
                Text(card.rank.label)
                    .font(.title3.bold())
                Text(card.suit.symbol)
                    .font(.title2)
            }
            .foregroundStyle(card.suit.isRed ? Color.red : Color.black)
        }
    }
    
    private var back: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.red.gradient)
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                .padding(5)
        }
    }
}

#Preview {
    HStack {
        CardView(card: Card(rank: .ace, suit: .spades))
        CardView(card: Card(rank: .queen, suit: .hearts))
        CardView(card: Card(rank: .seven, suit: .clubs))
        CardView(card: nil)
    }
}
