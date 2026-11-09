# Blackjack
A native iOS Blackjack game made with Swift/SwitUI. Game rules and mechanics live in an engine "BlackjackGame" and the SwiftUI layer just displays the state of the engine.

## Building and Running
There are no third-party dependencies or packages

1. Open "Blackjack.xcodeproj" in Xcode
2. Select "Blackjack" scheme and an iPhone sim
3. Press "Run"


## Dev Environment
Xcode: 27.2
iOS Sim: iPhone 18 Pro Max on iOS 27.2
Deployment target: iOS 17.0

## Additional Features
Betting: start with 1000 coins and make bets
Double Down: ability to double down on a hand
Split: ability to split hands
Insurance: dealer can offer insurance as a side bet
Game over and reset: game over when running out of chips
Hidden debug menu: log press the "Blackjack" title for 1.5 seconds
-    can edit every game rule
- force the first hand of a game with presets

## Structure
- Models/: cards, hand, shoe
- Engine/: game rules, BlackjackGame states and phases
- ViewModels/: "GameViewModel" connect the engine to the views
- Views/: SwiftUI screens and components
