//
//  BlackjackApp.swift
//  Blackjack
//
//  Created by Mark Brown
//

import SwiftUI

@main struct BlackjackApp: App {
    @State private var viewModel = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
        }
    }
}
