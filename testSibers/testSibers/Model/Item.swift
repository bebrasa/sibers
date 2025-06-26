//
//  Item.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

struct Item: Equatable {
    enum ItemType {
        case key
        case chest
        case torch
        case food
        case sword
        case gold(amount: Int)
    }
    
    let name: String
    let type: ItemType
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name
    }
}
