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
        return rooms[y][x]!
    }
    
    init() {
        self.player = Player(currentPosition: (0, 0))
        self.stepsLimit = 100
    }
    //MARK: Generating labyrinth
    func generateMaze(roomCount: Int) {
        let size = Int(ceil(sqrt(Double(roomCount))))
        
        rooms = Array(repeating: Array(repeating: nil, count: size), count: size)
        
        for y in 0..<size {
            for x in 0..<size {
                let possibleDirections = validDirections(for: x, y, size: size)
                let doorCount = min(Int.random(in: 1...4), possibleDirections.count)
                let doors = Array(possibleDirections.shuffled().prefix(doorCount))
                rooms[y][x] = Room(x: x, y: y, doors: doors, items: [])
            }
        }
        
        ensureConnectivity(size: size)
        
        let startX = Int.random(in: 0..<size)
        let startY = Int.random(in: 0..<size)
        player.currentPosition = (startX, startY)
        
        let keyPosition = findReachablePosition(size: size, exclude: (startX, startY))
        let chestPosition = findReachablePosition(size: size, exclude: keyPosition)
        
        rooms[keyPosition.y][keyPosition.x]?.items.append(Item(name: "Key", type: .key))
        rooms[chestPosition.y][chestPosition.x]?.items.append(Item(name: "Chest", type: .chest))
        
        let itemsToPlace = [
            Item(name: "Sword", type: .sword),
            Item(name: "Apple", type: .food),
            Item(name: "Bread", type: .food),
            Item(name: "Gold", type: .gold(amount: .random(in: 1...150))),
            Item(name: "Gold", type: .gold(amount: .random(in: 1...150)))
        ]
        
        for _ in 0..<(roomCount / 2) {
            if let randomItem = itemsToPlace.randomElement() {
                let position = findReachablePosition(size: size, exclude: (startX, startY))
                rooms[position.y][position.x]?.items.append(randomItem)
            }
        }
        for _ in 0..<(roomCount / 5) {
            let position = findReachablePosition(size: size, exclude: (startX, startY))
            rooms[position.y][position.x]?.items.append(Item(name: "Torch", type: .torch))
        }
        
        stepsLimit = size * 3
    }
    
    private func ensureConnectivity(size: Int) {
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        var queue = [(x: Int, y: Int)]()
        
        let startX = Int.random(in: 0..<size)
        let startY = Int.random(in: 0..<size)
        queue.append((startX, startY))
        visited[startY][startX] = true
        
        while !queue.isEmpty {
            let (x, y) = queue.removeFirst()
            let room = rooms[y][x]!
            
            for direction in room.doors {
                let (nx, ny) = neighborCoordinates(x: x, y: y, direction: direction)
                
                if nx >= 0, ny >= 0, nx < size, ny < size, !visited[ny][nx] {
                    visited[ny][nx] = true
                    queue.append((nx, ny))
                    
                    if rooms[ny][nx]!.doors.count < 4 &&
                       !rooms[ny][nx]!.doors.contains(oppositeDirection(direction)) {
                        rooms[ny][nx]!.doors.append(oppositeDirection(direction))
                    }
                }
            }
        }
        
        for y in 0..<size {
            for x in 0..<size {
                if !visited[y][x] {
                    connectIsolatedRoom(x: x, y: y, size: size, visited: &visited)
                }
            }
        }
    }
        
    private func connectIsolatedRoom(x: Int, y: Int, size: Int, visited: inout [[Bool]]) {
        let directions = validDirections(for: x, y, size: size)
        
        for direction in directions.shuffled() {
            let (nx, ny) = neighborCoordinates(x: x, y: y, direction: direction)
            
            if visited[ny][nx] {
                if rooms[y][x]!.doors.count < 4 &&
                   !rooms[y][x]!.doors.contains(direction) {
                    rooms[y][x]!.doors.append(direction)
                }
                
                let oppositeDir = oppositeDirection(direction)
                if rooms[ny][nx]!.doors.count < 4 &&
                   !rooms[ny][nx]!.doors.contains(oppositeDir) {
                    rooms[ny][nx]!.doors.append(oppositeDir)
                }
                
                visited[y][x] = true
                return
            }
        }
    }
        
    private func findReachablePosition(size: Int, exclude: (x: Int, y: Int)) -> (x: Int, y: Int) {
        var position = exclude
        
        while position == exclude {
            position = (Int.random(in: 0..<size), Int.random(in: 0..<size))
        }
        
        return position
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
    
    private func validDirections(for x: Int, _ y: Int, size: Int) -> [Direction] {
        var directions = [Direction]()
        
        if y > 0 { directions.append(.north) }
        if y < size - 1 { directions.append(.south) }
        if x > 0 { directions.append(.west) }
        if x < size - 1 { directions.append(.east) }
        
        return directions
    }
    
    func movePlayer(direction: Direction) {
        guard !isGameOver else { return }
        guard currentRoom.doors.contains(direction) else { return }
        
        var newPosition = player.currentPosition
        switch direction {
        case .north: newPosition.y -= 1
        case .south: newPosition.y += 1
        case .west:  newPosition.x -= 1
        case .east:  newPosition.x += 1
        }
        
        guard newPosition.x >= 0, newPosition.y >= 0,
              newPosition.x < rooms.count, newPosition.y < rooms.count,
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
