//
//  BoolRandom.swift
//  testSibers
//
//  Created by Никита Кочанов on 27.06.2025.
//

import Foundation

// MARK: - Bool+Random
extension Bool {
    // MARK: - Static Methods
    static func random(probability: Int) -> Bool {
        guard probability > 0 else { return false }
        guard probability < 100 else { return true }
        return Int.random(in: 1...100) <= probability
    }
}
