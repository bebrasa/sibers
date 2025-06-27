//
//  Room.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

// MARK: - Room
struct Room {
    // MARK: - Properties
    let x: Int
    let y: Int
    var doors: [Direction]
    var items: [Item]
    var isDark: Bool = false
}
