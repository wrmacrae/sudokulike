//
//  ContentView.swift
//  Sudoku
//
//  Created by William Macrae on 10/31/24.
//

import SwiftUI
import UIKit
import Foundation

let beginnerGrid = [[0, 3, 5, 0, 8, 0, 0, 0, 0],
                    [0, 0, 8, 3, 9, 0, 0, 0, 7],
                    [0, 1, 0, 6, 0, 0, 0, 4, 3],
                    [5, 0, 6, 8, 1, 0, 0, 0, 4],
                    [4, 0, 0, 0, 6, 0, 1, 8, 2],
                    [0, 0, 1, 9, 0, 4, 0, 6, 0],
                    [0, 6, 0, 0, 7, 0, 2, 1, 0],
                    [1, 0, 9, 0, 0, 6, 4, 0, 0],
                    [7, 0, 0, 1, 4, 9, 5, 0, 0]]
let hardGrid = [[0, 0, 0, 0, 8, 0, 0, 6, 0],
                [0, 3, 0, 5, 0, 0, 0, 0, 0],
                [0, 0, 6, 0, 9, 0, 2, 0, 0],
                [0, 6, 0, 0, 0, 4, 0, 0, 0],
                [0, 0, 0, 3, 0, 0, 0, 0, 8],
                [3, 5, 9, 0, 0, 0, 0, 0, 1],
                [0, 0, 0, 0, 0, 0, 0, 1, 0],
                [0, 1, 0, 9, 0, 0, 4, 0, 2],
                [0, 9, 0, 0, 3, 5, 0, 0, 0]]
enum PowerTypes : String {
    case nakedSingle
    case hiddenSingle
    case nakedDouble
    case hiddenDouble
}

@Observable
class Power : Identifiable {
    var currentTime: Double
    var label: String
    var timer: Timer.TimerPublisher
    var powerType: PowerTypes
    var level: Int = 0
    var experience: Int = 0

    init(label: String, timer: Timer.TimerPublisher, powerType: PowerTypes) {
        self.currentTime = 1_000_000_000.0
        self.label = label
        self.timer = timer
        self.powerType = powerType
        let canceller = timer.connect()
    }

    func maxTime() -> Double {
        switch level {
        case 0: return 1_000_000.0
        case 1: return 12.0
        case 2: return 5.0
        default: return 2.0
        }
    }
    func handleTimer() -> Bool {
        currentTime -= 0.1
        if currentTime <= 0 {
            currentTime = maxTime()
            return true
        }
        return false
    }
    func addExperience() -> Void {
        experience += 1
        if experience >= 5 {
            level += 1
            experience = 0
            currentTime = Double.minimum(currentTime, maxTime())
        }
    }

    func canSolve(grid: [[Int]], candidates: [[[Int]]]) -> Bool {
        switch powerType {
        case .nakedSingle : return autoNakedSingle(grid: grid, candidates: candidates) != grid
        case .hiddenSingle : return autoHiddenSingle(grid: grid, candidates: candidates) != grid
        case .nakedDouble : return autoNakedDouble(grid: grid, candidates: candidates) != candidates
        default: return false
        }
    }
}

struct ContentView: View {
    
    enum Actions : String, CaseIterable {
        //        case candidate
        //        case eliminate
        case fill
        case removeCandidate
        case addCandidate
        case clear
    }
    let t = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var powers: [Power] = [
        Power(label: "👤", timer: Timer.publish(every: 0.1, on: .main, in: .common), powerType: PowerTypes.nakedSingle),
        Power(label: "🙈", timer: Timer.publish(every: 0.1, on: .main, in: .common), powerType: PowerTypes.hiddenSingle),
        Power(label: "👥", timer: Timer.publish(every: 0.1, on: .main, in: .common), powerType: PowerTypes.nakedDouble)
    ]
    @State var startingGrid: [[Int]] = hardGrid
    @State var currentGrid: [[Int]] = hardGrid
    @State var candidates: [[[Int]]] = autoCandidates(hardGrid)
    @State var currentTarget: (Int?, Int?)
    @State var currentChoice: Int?
    @State var currentAction: Actions? = Actions.fill

    var body: some View {
        let size = UIScreen.main.bounds.width / 10.0
        HStack {
            ForEach(powers) { power in
                if (power.level > 0 || power.experience > 0) {
                    let percentCharged = power.currentTime / power.maxTime()
                    let percentExperience = Double(power.experience) / 5.0
                    VStack(spacing: 2) {
                        HStack {
                            ForEach (0..<3) { i in
                                Circle()
                                    .fill(power.level > i ? Color.blue : Color.white)
                                    .stroke(Color.black, lineWidth: 1)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        Text(power.label).onReceive(power.timer) { _ in
                            if (power.handleTimer()) {
                                switch power.powerType {
                                case .nakedSingle:
                                    nakedSingleSolve()
                                case .hiddenSingle:
                                    hiddenSingleSolve()
                                default:
                                    print("not yet implemented")
                                }
                            }
                        }.font(.largeTitle).background(Color(red: percentCharged, green: percentCharged, blue: percentCharged))
                        ZStack {
                            Capsule()
                                .fill(Color.white)
                                .stroke(.black, lineWidth: 1)
                                .frame(width: 40, height: 7)
                            Capsule()
                                .fill(.blue)
                                .frame(width: 40.0 * percentExperience, height: 7)
                        }
                    }
                }
            }
        }
        VStack(spacing: 0) {
            ForEach(0..<9) { i in
                let h = i.isMultiple(of: 3) ? 4.0 : 1.0
                Divider().frame(width: size*9+22, height: h).background(Color.black)
                HStack(spacing: 0) {
                    ForEach(0..<9) { j in
                        let w = j.isMultiple(of: 3) ? 4.0 : 1.0
                        Divider().frame(width: w, height: size).background(Color.black)
                        ZStack {
                            let label: String = currentGrid[i][j] > 0 ? String(currentGrid[i][j]) : " "
                            let tint: Color = startingGrid[i][j] > 0 ? .black : .black
                            let background: Color = (currentTarget == (i, j)) ? Color(red: 0.6, green: 0.7, blue: 0.9, opacity: 1.0) : startingGrid[i][j] > 0 ? Color(red: 0.85, green: 0.85, blue: 0.87, opacity: 1.0) : .white
                            Button(action: setTargetMaker(i: i,j: j), label: {
                                Text(label)
                                .frame(width: size, height: size)
                                .tint(tint)
                                .background(background)
                            })
                            HStack(spacing: 0) {
                                ForEach(0..<3) { col in
                                    VStack(spacing: 0) {
                                        ForEach(0..<3) { row in
                                            let n = col + 3 * row + 1
                                            if (candidates[i][j].contains(n) && currentGrid[i][j] == 0) {
                                                Text(String(n))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .frame(width: size/3.0, height: size/3.0)
                                            } else {
                                                Text(String(" "))
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                    .frame(width: size/3.0, height: size/3.0)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Divider().frame(width: 4.0, height: size).background(Color.black)
                }
            }
            Divider().frame(width: size*9+22, height: 4.0).background(Color.black)
        }
        HStack() {
            VStack() {
                ForEach(Actions.allCases, id: \.self) { action in
                    if (currentAction == action) {
                        Button(action.rawValue.capitalized, action: setActionMaker(action: action))
                            .frame(width: size*4.5, height: size*1)
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button(action.rawValue.capitalized, action: setActionMaker(action: action))
                            .frame(width: size*4.5, height: size*1)
                            .buttonStyle(.bordered)
                        
                    }
                }
            }
            HStack() {
                ForEach(0..<3) { col in
                    VStack() {
                        ForEach(0..<3) { row in
                            let n = col + 3 * row + 1
                            if (currentChoice == n) {
                                Button(String(n), action: setChoiceMaker(n: n))
                                    .frame(width: size*1.5, height: size*1.5)
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button(String(n), action: setChoiceMaker(n: n))
                                    .frame(width: size*1.5, height: size*1.5)
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func nakedSingleSolve() -> Void {
        currentGrid = autoNakedSingle(grid: currentGrid, candidates: candidates)
        candidates = autoCandidates(currentGrid, candidates: candidates)
    }

    func hiddenSingleSolve() -> Void {
        currentGrid = autoHiddenSingle(grid: currentGrid, candidates: candidates)
        candidates = autoCandidates(currentGrid, candidates: candidates)
    }

    func setTarget(i: Int?, j: Int?)
    {
        currentTarget = (i, j)
        setChoice(n: nil)
        tryAction()
    }
    
    func setTargetMaker(i: Int, j: Int) -> () -> () {
        return {() in setTarget(i: i, j: j)}
    }
    
    func setChoice(n: Int?) {
        currentChoice = n
        tryAction()
    }
    
    func setChoiceMaker(n: Int) -> () -> () {
        return {() in setChoice(n: n)}
    }
    
    func setAction(action: Actions) {
        currentAction = action
        setChoice(n: nil)
        setTarget(i: nil, j: nil)
    }
    
    func setActionMaker(action: Actions) -> () -> () {
        return {() in setAction(action: action)}
    }
    
    func creditExperience() {
        for power in powers {
            if (power.canSolve(grid: currentGrid, candidates: candidates)) {
                power.addExperience()
                return
            }
        }
    }
    
    func tryAction() {
        guard currentAction != nil && currentTarget.0 != nil && currentTarget.1 != nil else { return }
        switch (currentAction) {
            //        case .candidate:
            //        case .eliminate:
        case .fill:
            guard startingGrid[currentTarget.0!][currentTarget.1!] == 0 else { break }
            guard currentChoice != nil else { break }
            creditExperience()
            currentGrid[currentTarget.0!][currentTarget.1!] = currentChoice!
        case .clear:
            guard startingGrid[currentTarget.0!][currentTarget.1!] == 0 else { break }
            currentGrid[currentTarget.0!][currentTarget.1!] = 0
        case .removeCandidate:
            guard currentGrid[currentTarget.0!][currentTarget.1!] == 0 else { break }
            guard currentChoice != nil else { break }
            guard candidates[currentTarget.0!][currentTarget.1!].contains(currentChoice!) else { break }
            creditExperience()
            candidates[currentTarget.0!][currentTarget.1!].removeAll(where: { $0 == currentChoice! })
        case .addCandidate:
            guard currentGrid[currentTarget.0!][currentTarget.1!] == 0 else { break }
            guard currentChoice != nil else { break }
            if (candidates[currentTarget.0!][currentTarget.1!].contains(currentChoice!)) { break }
            candidates[currentTarget.0!][currentTarget.1!].append(currentChoice!)
        case .none:
            break
        }
        candidates = autoCandidates(currentGrid, candidates: candidates)
    }
}
func autoCandidates(_ grid : [[Int]]) -> [[[Int]]] {
    return autoCandidates(grid, candidates: [[[Int]]](repeating: [[Int]](repeating: [Int](1...9), count: 9), count: 9))
}

func autoCandidates(_ grid : [[Int]], candidates: [[[Int]]]) -> [[[Int]]] {
    var newCandidates = [[[Int]]](repeating: [[Int]](repeating: [], count: 9), count: 9)

    for i in 0 ..< 9 {
        for j in 0 ..< 9 {
            if grid[i][j] == 0 {
                newCandidates[i][j] = candidates[i][j].filter({!conflict(grid: grid, i: i, j: j, n: $0)})
            } else {
                newCandidates[i][j] = []
            }
        }
    }
    return newCandidates
}

func autoNakedSingle(grid : [[Int]], candidates: [[[Int]]]) -> [[Int]] {
    var newGrid = grid
    for i in 0 ..< 9 {
        for j in 0 ..< 9 {
            if candidates[i][j].count == 1 && newGrid[i][j] == 0 {
                newGrid[i][j] = candidates[i][j][0]
                return newGrid
            }
        }
    }
    return newGrid
}

func autoHiddenSingle(grid : [[Int]], candidates: [[[Int]]]) -> [[Int]] {
    var newGrid = grid
    for i in 0 ..< 9 {
        for j in 0 ..< 9 {
            for candidate in candidates[i][j] {
                if onlyInRow(candidate, candidates: candidates, row: i, col: j) || onlyInColumn(candidate, candidates: candidates, row: i, col: j) || onlyInHouse(candidate, candidates: candidates, row: i, col: j) {
                    newGrid[i][j] = candidate
                    return newGrid
                }
            }
        }
    }
    return newGrid
}

func autoNakedDouble(grid : [[Int]], candidates: [[[Int]]]) -> [[[Int]]] {
    for i in 0 ..< 9 {
        for j in 0 ..< 9 {
            if candidates[i][j].count == 2 && grid[i][j] == 0 {
                if doubleInRow(candidates[i][j], candidates: candidates, row: i) {
                    return handleNakedDoubleInRow(candidates[i][j], candidates: candidates, row: i)
                }
                if doubleInColumn(candidates[i][j], candidates: candidates, column: j) {
                    return handleNakedDoubleInColumn(candidates[i][j], candidates: candidates, column: j)
                }
                if doubleInHouse(candidates[i][j], candidates: candidates, row: i, column: j) {
                    return handleNakedDoubleInHouse(candidates[i][j], candidates: candidates, row: i, column: j)
                }
            }
        }
    }
    return candidates
}

func onlyInRow(_ n: Int, candidates: [[[Int]]], row: Int, col: Int) -> Bool {
    for j in 0 ..< 9 {
        if (j != col && candidates[row][j].contains(n)) {
            return false
        }
    }
    return true
}

func onlyInColumn(_ n: Int, candidates: [[[Int]]], row: Int, col: Int) -> Bool {
    for i in 0 ..< 9 {
        if (i != row && candidates[i][col].contains(n)) {
            return false
        }
    }
    return true
}

func onlyInHouse(_ n: Int, candidates: [[[Int]]], row: Int, col: Int) -> Bool {
    for drow in 0 ..< 3 {
        for dcol in 0 ..< 3 {
            if (drow + dcol > 0 && candidates[row/3*3 + (row+drow)%3][col/3*3 + (col+dcol)%3].contains(n)) {
                return false
            }
        }
    }
    return true
}

func doubleInRow(_ double : [Int], candidates: [[[Int]]], row: Int) -> Bool {
    var count = 0
    for j in 0 ..< 9 {
        if candidates[row][j].sorted() == double.sorted() {
            count += 1
        }
    }
    return count == 2
}

func doubleInColumn(_ double : [Int], candidates: [[[Int]]], column: Int) -> Bool {
    var count = 0
    for i in 0 ..< 9 {
        if candidates[i][column].sorted() == double.sorted() {
            count += 1
        }
    }
    return count == 2
}

func doubleInHouse(_ double : [Int], candidates: [[[Int]]], row: Int, column: Int) -> Bool {
    var count = 0
    for drow in 0 ..< 3 {
        for dcol in 0 ..< 3 {
            if candidates[row/3*3 + (row+drow)%3][column/3*3 + (column+dcol)%3].sorted() == double.sorted() {
                count += 1
            }
        }
    }
    return count == 2
}

func handleNakedDoubleInRow(_ double : [Int], candidates: [[[Int]]], row: Int) -> [[[Int]]] {
    var newCandidates = candidates
    for j in 0 ..< 9 {
        if newCandidates[row][j].sorted() != double.sorted() {
            newCandidates[row][j].removeAll(where: { double.contains($0) })
        }
    }
    return newCandidates
}

func handleNakedDoubleInColumn(_ double : [Int], candidates: [[[Int]]], column: Int) -> [[[Int]]] {
    var newCandidates = candidates
    for i in 0 ..< 9 {
        if newCandidates[i][column].sorted() != double.sorted() {
            newCandidates[i][column].removeAll(where: { double.contains($0) })
        }
    }
    return newCandidates
}

func handleNakedDoubleInHouse(_ double : [Int], candidates: [[[Int]]], row: Int, column: Int) -> [[[Int]]] {
    var newCandidates = candidates
    for drow in 0 ..< 3 {
        for dcol in 0 ..< 3 {
            if newCandidates[row/3*3 + (row+drow)%3][column/3*3 + (column+dcol)%3].sorted() != double.sorted() {
                newCandidates[row/3*3 + (row+drow)%3][column/3*3 + (column+dcol)%3].removeAll(where: { double.contains($0) })
            }
        }
    }
    return newCandidates
}

func conflict(grid: [[Int]], i: Int, j: Int, n: Int) -> Bool {
    for x in 0 ..< 9 {
        if x != i && grid[x][j] == n {
            return true
        }
    }
    for y in 0 ..< 9 {
        if y != j && grid[i][y] == n {
            return true
        }
    }
    for dx in 0 ..< 3 {
        for dy in 0 ..< 3 {
            let x = i/3*3 + (i+dx)%3
            let y = j/3*3 + (j+dy)%3
            if (x != i || y != j) && grid[x][y] == n {
                return true
            }
        }
    }
    return false
}


#Preview {
    ContentView()
}
