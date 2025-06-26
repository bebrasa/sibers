//
//  GamePresenter.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

import Foundation

protocol GamePresenterProtocol {
    var view: GameViewProtocol? { get set }
    func startGame(roomCount: Int)
    func handleCommand(_ command: String)
}

class GamePresenter: GamePresenterProtocol {
    weak var view: GameViewProtocol?
    private let gameWorld: GameWorldProtocol
    
    init(gameWorld: GameWorldProtocol = GameWorld()) {
        self.gameWorld = gameWorld
    }
    
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
        
        switch action {
        case "n", "s", "w", "e":
            handleMovementCommand(String(action))
            
        case "get":
            handleGetCommand(parts: Array(parts.dropFirst()))
            
        case "drop":
            handleDropCommand(parts: Array(parts.dropFirst()))
            
        case "open":
            handleOpenCommand(parts: Array(parts.dropFirst()))
            
        case "inventory":
            displayInventory()
            
        default:
            view?.displayError("Unknown command: \(command)")
        }
    }
    
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
            if case .gold = gameWorld.player.inventory.first(where: { $0.name.lowercased() == itemName })?.type {
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
        if gameWorld.dropItem(named: itemName) {
            view?.displayText("You dropped \(itemName)")
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
        let healthInfo = "\nHealth: \(gameWorld.player.health)%"
        var description = "You are in the room [\(room.x),\(room.y)]. "
        description += "There are \(room.doors.count) doors: \(room.doors.map { $0.rawValue }.joined(separator: ", ")). "
        
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
