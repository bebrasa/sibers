//
//  GameWorld.swift
//  testSibers
//
//  Created by Никита Кочанов on 26.06.2025.
//

import Foundation

// MARK: - GameWorldProtocol
protocol GameWorldProtocol {
    var player: Player { get }
    var currentRoom: Room { get }
    var stepsLimit: Int { get }
    var isGameOver: Bool { get }
    
    func generateMaze(roomCount: Int)
    func movePlayer(direction: Direction)
    func pickupItem(named: String) -> Bool
    func dropItem(named: String) -> Bool
    func openChest() -> Bool
    func useItem(named: String) -> Bool
}

// MARK: - GameWorld
class GameWorld: GameWorldProtocol {
    private(set) var rooms: [[Room?]] = []
    private(set) var player: Player
    private(set) var stepsLimit: Int
    private(set) var isGameOver = false
    
    var currentRoom: Room {
        let (x, y) = player.currentPosition
        guard y >= 0, y < rooms.count,
              x >= 0, x < rooms[y].count,
              let room = rooms[y][x] else {
            fatalError("Invalid player position: \(player.currentPosition)")
        }
        return room
    }
    
    init() {
        self.player = Player(currentPosition: (0, 0))
        self.stepsLimit = 100
    }
    
    //MARK: Generating labyrinth
    func generateMaze(roomCount: Int) {
        
        let width = Int(ceil(sqrt(Double(roomCount))))
        let height = (roomCount + width - 1) / width
        
        rooms = Array(repeating: Array(repeating: nil, count: width), count: height)
        
        var allCoordinates: [(x: Int, y: Int)] = []
        for y in 0..<height {
            for x in 0..<width {
                allCoordinates.append((x, y))
            }
        }
        
        let selectedCoordinates = Array(allCoordinates.shuffled().prefix(roomCount))
        
        for coord in selectedCoordinates {
            let possibleDirections = validDirections(for: coord.x, coord.y, width: width, height: height)
            let doorCount = min(Int.random(in: 1...4), possibleDirections.count)
            let doors = Array(possibleDirections.shuffled().prefix(doorCount))
            rooms[coord.y][coord.x] = Room(x: coord.x, y: coord.y, doors: doors, items: [])
        }
        
        ensureConnectivity(width: width, height: height, selectedCoordinates: selectedCoordinates)
        
        if let startCoord = selectedCoordinates.randomElement() {
            player.currentPosition = (startCoord.x, startCoord.y)
        }
        
        let keyPosition = findReachablePosition(selectedCoordinates: selectedCoordinates, exclude: player.currentPosition)
        let chestPosition = findReachablePosition(selectedCoordinates: selectedCoordinates, exclude: keyPosition)
        
        rooms[keyPosition.y][keyPosition.x]?.items.append(Item(name: "Key", type: .key))
        rooms[chestPosition.y][chestPosition.x]?.items.append(Item(name: "Chest", type: .chest))
        
        let itemsToPlace = [
            Item(name: "Torch", type: .torch),
            Item(name: "Sword", type: .sword),
            Item(name: "Apple", type: .food),
            Item(name: "Bread", type: .food),
            Item(name: "Gold", type: .gold(amount: .random(in: 1...150)))
        ]
        
        for _ in 0..<(roomCount / 5) {
            if let coord = selectedCoordinates.randomElement() {
                rooms[coord.y][coord.x]?.items.append(Item(name: "Torch", type: .torch))
            }
        }
        
        for _ in 0..<(roomCount / 2) {
            if let randomItem = itemsToPlace.randomElement(),
               let coord = selectedCoordinates.randomElement() {
                rooms[coord.y][coord.x]?.items.append(randomItem)
            }
        }
        
        stepsLimit = roomCount * 2
    }
    
    private func ensureConnectivity(width: Int, height: Int, selectedCoordinates: [(x: Int, y: Int)]) {
        var visited = Set<[Int]>()
        var queue = [(x: Int, y: Int)]()
        
        guard let start = selectedCoordinates.first else { return }
        queue.append(start)
        visited.insert([start.x, start.y])
        
        while !queue.isEmpty {
            let coord = queue.removeFirst()
            
            for direction in Direction.allCases {
                let (nx, ny) = neighborCoordinates(x: coord.x, y: coord.y, direction: direction)
                
                guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                
                guard rooms[ny][nx] != nil else { continue }
                
                let neighbor = (nx, ny)
                let neighborKey = [nx, ny]
                
                if !visited.contains(neighborKey) {
                    visited.insert(neighborKey)
                    queue.append(neighbor)
                    
                    if var room = rooms[coord.y][coord.x],
                       !room.doors.contains(direction) {
                        room.doors.append(direction)
                        rooms[coord.y][coord.x] = room
                    }
                    
                    let opposite = oppositeDirection(direction)
                    if var neighborRoom = rooms[ny][nx],
                       !neighborRoom.doors.contains(opposite) {
                        neighborRoom.doors.append(opposite)
                        rooms[ny][nx] = neighborRoom
                    }
                }
            }
        }
    }
    
    private func findReachablePosition(selectedCoordinates: [(x: Int, y: Int)], exclude: (x: Int, y: Int)) -> (x: Int, y: Int) {
        let filteredCoords = selectedCoordinates.filter { coord in
            coord.x != exclude.x || coord.y != exclude.y
        }
        return filteredCoords.randomElement() ?? exclude
    }
    
    private func neighborCoordinates(x: Int, y: Int, direction: Direction) -> (Int, Int) {
        switch direction {
        case .north: return (x, y-1)
        case .south: return (x, y+1)
        case .west: return (x-1, y)
        case .east: return (x+1, y)
        }
    }
    
    private func oppositeDirection(_ direction: Direction) -> Direction {
        switch direction {
        case .north: return .south
        case .south: return .north
        case .west: return .east
        case .east: return .west
        }
    }
    
    func useItem(named itemName: String) -> Bool {
        return player.useItem(named: itemName)
    }
    
    private func validDirections(for x: Int, _ y: Int, width: Int, height: Int) -> [Direction] {
        var directions = [Direction]()
        
        if y > 0 && rooms[y-1][x] != nil { directions.append(.north) }
        if y < height - 1 && rooms[y+1][x] != nil { directions.append(.south) }
        if x > 0 && rooms[y][x-1] != nil { directions.append(.west) }
        if x < width - 1 && rooms[y][x+1] != nil { directions.append(.east) }
        
        return directions
    }
    
    func movePlayer(direction: Direction) {
        guard !isGameOver else { return }
        
        let (x, y) = player.currentPosition
        guard rooms[y][x]?.doors.contains(direction) == true else { return }
        
        var newPosition = (x: x, y: y)
        switch direction {
        case .north: newPosition.y -= 1
        case .south: newPosition.y += 1
        case .west: newPosition.x -= 1
        case .east: newPosition.x += 1
        }
        
        guard newPosition.y >= 0, newPosition.y < rooms.count,
              newPosition.x >= 0, newPosition.x < rooms[newPosition.y].count,
              rooms[newPosition.y][newPosition.x] != nil else {
            return
        }
        
        player.currentPosition = newPosition
        player.health -= 1
        
        if player.health <= 0 {
            isGameOver = true
        }
    }
}

extension GameWorld {
    func pickupItem(named itemName: String) -> Bool {
        guard let roomIndex = getCurrentRoomIndex(),
              let itemIndex = rooms[roomIndex.y][roomIndex.x]?.items.firstIndex(where: {
                  $0.name.lowercased() == itemName.lowercased()
              }) else {
            return false
        }
        
        let item = rooms[roomIndex.y][roomIndex.x]!.items.remove(at: itemIndex)
        
        if case .gold(let amount) = item.type {
            player.gold += amount
            return true
        }
        
        if case .chest = item.type {
            rooms[roomIndex.y][roomIndex.x]?.items.append(item)
            return false
        }
        
        player.inventory.append(item)
        return true
    }
    
    func dropItem(named itemName: String) -> Bool {
        guard let itemIndex = player.inventory.firstIndex(where: {
                  $0.name.lowercased() == itemName.lowercased()
              }),
              let roomIndex = getCurrentRoomIndex() else {
            return false
        }
        
        let item = player.inventory.remove(at: itemIndex)
        rooms[roomIndex.y][roomIndex.x]?.items.append(item)
        return true
    }
    
    func openChest() -> Bool {
        guard let roomIndex = getCurrentRoomIndex(),
              rooms[roomIndex.y][roomIndex.x]?.items.contains(where: {
                  if case .chest = $0.type { return true }
                  return false
              }) == true,
              player.hasItem(ofType: .key) else {
            return false
        }
        
        isGameOver = true
        return true
    }
    
    private func getCurrentRoomIndex() -> (x: Int, y: Int)? {
        let (x, y) = player.currentPosition
        guard y >= 0, y < rooms.count,
              x >= 0, x < rooms[y].count,
              rooms[y][x] != nil else {
            return nil
        }
        return (x, y)
    }
}
