//
//  Item.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

// MARK: - Item
struct Item: Equatable {
    // MARK: - ItemType
    enum ItemType: Equatable {
        case key
        case chest
        case torch
        case food
        case sword
        case gold(amount: Int)
    }
    // MARK: - Properties
    let name: String
    let type: ItemType
    // MARK: - Equatable
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
}
