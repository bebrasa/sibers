//
//  ConsoleView.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

import Foundation

// MARK: - GameViewProtocol
protocol GameViewProtocol: AnyObject {
    func displayRoomDescription(_ description: String)
    func displayInventory(_ items: [String])
    func displayGameOver(message: String)
    func displayError(_ message: String)
    func displayText(_ text: String)
}

// MARK: - GameView
class ConsoleView: GameViewProtocol {
    // MARK: - Properties
    private var presenter: GamePresenterProtocol
    
    // MARK: - Init
    init() {
        self.presenter = GamePresenter()
        self.presenter.view = self
        
        print("Welcome to Dragons & Crystals!\n")
        print("To show inventory type: `inventory")
        print("To healing you need to eat, type 'eat' followed by the name of an item")
        print("You also can use get, drop, open commands\n")
        
        startGame()
    }
    
    // MARK: - Private Methods
    private func startGame() {
        print("Enter number of rooms: ")
        
        if let input = readLine(), let roomCount = Int(input), roomCount > 0 {
            presenter.startGame(roomCount: roomCount)
            gameLoop()
        } else {
            print("Invalid input. Please enter a number.")
            startGame()
        }
    }
    
    private func gameLoop() {
        while true {
            print("\n> ", terminator: "")
            if let command = readLine() {
                presenter.handleCommand(command)
            }
        }
    }
    
    // MARK: - GameViewProtocol
    func displayText(_ text: String) {
        print(text)
    }
    
    func displayRoomDescription(_ description: String) {
        print("\n=== Room Description ===")
        print(description)
        print("========================")
    }
    
    func displayInventory(_ items: [String]) {
        print("\nInventory:")
        print(items.joined(separator: "\n"))
    }
    
    func displayGameOver(message: String) {
        print("\n!!! GAME OVER !!!")
        print(message)
        exit(0)
    }
    
    func displayError(_ message: String) {
        print("Error: \(message)")
    }
}
