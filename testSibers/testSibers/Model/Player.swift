//
//  Player.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

struct Player {
    var currentPosition: (x: Int, y: Int)
    var inventory: [Item] = []
    var health: Int = 100
    var gold: Int = 0
    
    func hasItem(named itemName: String) -> Bool {
        inventory.contains { $0.name.lowercased() == itemName.lowercased() }
    }
    
    func hasItem(ofType type: Item.ItemType) -> Bool {
        inventory.contains { item in
            switch (item.type, type) {
            case (.gold, .gold): return true
            case (.key, .key): return true
            case (.chest, .chest): return true
            case (.torch, .torch): return true
            case (.food, .food): return true
            case (.sword, .sword): return true
            default: return false
            }
        }
    }
}
