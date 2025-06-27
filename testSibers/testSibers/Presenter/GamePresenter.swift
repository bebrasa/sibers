//
//  GamePresenter.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

import Foundation

// MARK: - GamePresenterProtocol
protocol GamePresenterProtocol {
    var view: GameViewProtocol? { get set }
    func startGame(roomCount: Int)
    func handleCommand(_ command: String)
}

// MARK: - GamePresenter
class GamePresenter: GamePresenterProtocol {
    // MARK: - Properties
    weak var view: GameViewProtocol?
    private let gameWorld: GameWorldProtocol
    
    // MARK: - Init
    init(gameWorld: GameWorldProtocol = GameWorld()) {
        self.gameWorld = gameWorld
    }
    
    // MARK: - GamePresenterProtocol
    func startGame(roomCount: Int) {
        gameWorld.generateMaze(roomCount: roomCount)
        updateRoomDescription()
    }
    
    func handleCommand(_ command: String) {
        let parts = command.lowercased().split(separator: " ")
        guard let action = parts.first else {
            view?.displayError("Empty command")
            return
        }
        
        let currentRoom = gameWorld.currentRoom
        if currentRoom.isDark && !gameWorld.isCurrentRoomIlluminated() {
            switch action {
            case "n", "s", "w", "e":
                handleMovementCommand(String(action))
            default:
                view?.displayError("You can't do that in the dark!")
                return
            }
        }
        else {
            switch action {
            case "n", "s", "w", "e":
                handleMovementCommand(String(action))
                
            case "get":
                handleGetCommand(parts: Array(parts.dropFirst()))
                
            case "drop":
                handleDropCommand(parts: Array(parts.dropFirst()))
                
            case "eat":
                handleEatCommand(parts: Array(parts.dropFirst()))
                
            case "open":
                handleOpenCommand(parts: Array(parts.dropFirst()))
                
            case "inventory":
                displayInventory()
                
            default:
                view?.displayError("Unknown command: \(command)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func handleMovementCommand(_ direction: String) {
        guard let direction = Direction(rawValue: direction.uppercased()) else {
            view?.displayError("Invalid direction")
            return
        }
        
        gameWorld.movePlayer(direction: direction)
        updateRoomDescription()
        
        if gameWorld.isGameOver {
            view?.displayGameOver(message: "You died of hunger in the dragon's cave!")
        }
    }
    
    private func handleGetCommand(parts: [Substring]) {
        guard !parts.isEmpty else {
            view?.displayError("Specify item to pick up")
            return
        }
        
        let itemName = parts.joined(separator: " ")
        if gameWorld.pickupItem(named: itemName) {
            if itemName.lowercased() == "torch" {
                view?.displayText("You picked up a torch! Now you can explore dark places.")
            } else if case .gold = gameWorld.player.inventory.first(where: { $0.name.lowercased() == itemName })?.type {
                view?.displayText("You picked up gold!")
            } else {
                view?.displayText("You picked up \(itemName)")
            }
            updateRoomDescription()
        } else {
            view?.displayError("Can't pick up \(itemName)")
        }
    }
    
    private func handleDropCommand(parts: [Substring]) {
        guard !parts.isEmpty else {
            view?.displayError("Specify item to drop")
            return
        }
        
        let itemName = parts.joined(separator: " ")
        let currentRoom = gameWorld.currentRoom
        
        if gameWorld.dropItem(named: itemName) {
            if itemName.lowercased() == "torch" && currentRoom.isDark {
                gameWorld.illuminateCurrentRoom()
                view?.displayText("You dropped the torch, illuminating the room!")
            } else {
                view?.displayText("You dropped \(itemName)")
            }
            updateRoomDescription()
        } else {
            view?.displayError("Can't drop \(itemName)")
        }
    }
    
    private func handleOpenCommand(parts: [Substring]) {
        guard !parts.isEmpty, parts[0] == "chest" else {
            view?.displayError("Specify what to open (e.g. 'open chest')")
            return
        }
        
        if gameWorld.openChest() {
            view?.displayGameOver(message: "Congratulations! You found the Holy Grail!")
        } else {
            view?.displayError("Can't open chest. You need a key")
        }
    }
    
    private func handleEatCommand(parts: [Substring]) {
        guard !parts.isEmpty else {
            view?.displayError("Specify item to eat")
            return
        }
        
        let itemName = parts.joined(separator: " ")
        if gameWorld.useItem(named: itemName) {
            view?.displayText("You ate \(itemName). Health increased to \(gameWorld.player.health)%")
        } else {
            view?.displayError("You cannot eat \(itemName) or it's not in your inventory")
        }
    }
    
    private func displayInventory() {
        let inventoryList = gameWorld.player.inventory.map { item in
            switch item.type {
            case .gold(let amount):
                return "\(item.name) (\(amount) coins)"
            default:
                return item.name
            }
        }
        
        let goldInfo = gameWorld.player.gold > 0 ? "\nGold: \(gameWorld.player.gold) coins" : ""
        
        view?.displayText("""
        Inventory:
        \(inventoryList.joined(separator: "\n"))\(goldInfo)
        """)
    }
    
    private func updateRoomDescription() {
        let room = gameWorld.currentRoom
        
        if room.isDark && !gameWorld.isCurrentRoomIlluminated() {
            view?.displayRoomDescription("Can't see anything in this dark place!\nThere are \(room.doors.count) doors: \(room.doors.map { $0.rawValue }.joined(separator: ", ")). ")
            return
        }
        
        let healthInfo = "\nHealth: \(gameWorld.player.health)%"
        var description = "You are in the room [\(room.x),\(room.y)]. "
        description += "There are \(room.doors.count) doors: \(room.doors.map { $0.rawValue }.joined(separator: ", ")). \n"
        if room.isDark {
            description += "It is dark. "
        }
        
        if !room.items.isEmpty {
            let itemsDescription = room.items.map { item in
                switch item.type {
                case .gold(let amount):
                    return "\(item.name) (\(amount) coins)"
                default:
                    return item.name
                }
            }.joined(separator: ", ")
            
            description += "Items in the room: \(itemsDescription)"
            description += "\(healthInfo)"
        }
        else {
            description += "\(healthInfo)"
        }
        
        view?.displayRoomDescription(description)
    }
}
