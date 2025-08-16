import XCTest
import Combine
@testable import Touch_Grass

final class WaterTrackingTests: XCTestCase {
    var waterTracker: WaterTracker!
    var preferencesStore: TestPreferencesStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        preferencesStore = TestPreferencesStore()
        waterTracker = WaterTracker()
        cancellables = []
        
        // Reset water tracking for clean tests
        waterTracker.resetDaily()
    }
    
    override func tearDown() {
        cancellables = nil
        waterTracker = nil
        preferencesStore = nil
        
        super.tearDown()
    }
    
    func testDailyGoalTracking() {
        // Given: Daily goal of 8 glasses
        waterTracker.dailyGoal = 8
        waterTracker.selectedUnit = .glasses
        
        // When: Logging water throughout the day
        waterTracker.addWater(amount: 2)
        XCTAssertEqual(waterTracker.todayTotal, 2)
        XCTAssertEqual(waterTracker.progressPercentage, 0.25)
        
        waterTracker.addWater(amount: 3)
        XCTAssertEqual(waterTracker.todayTotal, 5)
        XCTAssertEqual(waterTracker.progressPercentage, 0.625)
        
        waterTracker.addWater(amount: 3)
        XCTAssertEqual(waterTracker.todayTotal, 8)
        XCTAssertEqual(waterTracker.progressPercentage, 1.0)
        
        // Can exceed goal
        waterTracker.addWater(amount: 2)
        XCTAssertEqual(waterTracker.todayTotal, 10)
        XCTAssertEqual(waterTracker.progressPercentage, 1.25)
    }
    
    func testUnitConversion() {
        // Test 1: Ounces
        waterTracker.selectedUnit = .ounces
        waterTracker.dailyGoal = 64
        waterTracker.addWater(amount: 16)
        XCTAssertEqual(waterTracker.progressPercentage, 0.25)
        
        // Test 2: Milliliters
        waterTracker.resetDaily()
        waterTracker.selectedUnit = .milliliters
        waterTracker.dailyGoal = 2000
        waterTracker.addWater(amount: 500)
        XCTAssertEqual(waterTracker.progressPercentage, 0.25)
        
        // Test 3: Glasses (default)
        waterTracker.resetDaily()
        waterTracker.selectedUnit = .glasses
        waterTracker.dailyGoal = 8
        waterTracker.addWater(amount: 2)
        XCTAssertEqual(waterTracker.progressPercentage, 0.25)
    }
    
    func testDailyReset() {
        // Given: Some water logged today
        waterTracker.dailyGoal = 8
        waterTracker.addWater(amount: 5)
        XCTAssertEqual(waterTracker.todayTotal, 5)
        
        // When: Simulating next day
        simulateNextDay()
        waterTracker.checkAndResetIfNewDay()
        
        // Then: Should reset to zero
        XCTAssertEqual(waterTracker.todayTotal, 0)
        XCTAssertEqual(waterTracker.progressPercentage, 0)
    }
    
    func testStreakTracking() {
        waterTracker.dailyGoal = 8
        waterTracker.resetStreak()
        
        // Day 1: Meet goal
        waterTracker.addWater(amount: 8)
        waterTracker.updateStreakIfGoalMet()
        XCTAssertEqual(waterTracker.currentStreak, 1)
        
        // Day 2: Meet goal
        simulateNextDay()
        waterTracker.checkAndResetIfNewDay()
        waterTracker.addWater(amount: 8)
        waterTracker.updateStreakIfGoalMet()
        XCTAssertEqual(waterTracker.currentStreak, 2)
        
        // Day 3: Don't meet goal
        simulateNextDay()
        waterTracker.checkAndResetIfNewDay()
        waterTracker.addWater(amount: 4) // Only half
        simulateNextDay() // Move to next day without meeting goal
        waterTracker.checkAndResetIfNewDay()
        XCTAssertEqual(waterTracker.currentStreak, 0)
    }
    
    func testPersistence() {
        // Given: Some water tracking data
        waterTracker.dailyGoal = 10
        waterTracker.selectedUnit = .ounces
        waterTracker.addWater(amount: 32)
        let originalTotal = waterTracker.todayTotal
        
        // When: Creating new tracker (simulating app restart)
        let newTracker = WaterTracker()
        
        // Then: Should restore persisted data
        XCTAssertEqual(newTracker.dailyGoal, 10)
        XCTAssertEqual(newTracker.selectedUnit, .ounces)
        XCTAssertEqual(newTracker.todayTotal, originalTotal)
    }
    
    func testQuickAddButtons() {
        // Test the standard quick-add amounts
        waterTracker.selectedUnit = .glasses
        waterTracker.dailyGoal = 8
        
        // +1 glass button
        waterTracker.quickAdd(.oneGlass)
        XCTAssertEqual(waterTracker.todayTotal, 1)
        
        // +8oz button
        waterTracker.quickAdd(.eightOunces)
        XCTAssertEqual(waterTracker.todayTotal, 2) // Assuming 1 glass = 8oz
        
        // +250ml button
        waterTracker.quickAdd(.twoFiftyML)
        XCTAssertEqual(waterTracker.todayTotal, 3) // Assuming conversion
    }
    
    func testProgressNotifications() {
        var progressUpdates: [Double] = []
        
        waterTracker.$progressPercentage
            .sink { progress in
                progressUpdates.append(progress)
            }
            .store(in: &cancellables)
        
        waterTracker.dailyGoal = 4
        waterTracker.addWater(amount: 1)
        waterTracker.addWater(amount: 1)
        waterTracker.addWater(amount: 1)
        waterTracker.addWater(amount: 1)
        
        // Should have progress updates at 0%, 25%, 50%, 75%, 100%
        XCTAssertEqual(progressUpdates.last, 1.0)
        XCTAssertTrue(progressUpdates.contains(0.25))
        XCTAssertTrue(progressUpdates.contains(0.5))
        XCTAssertTrue(progressUpdates.contains(0.75))
    }
    
    func testHistoricalData() {
        // Test tracking historical water intake
        var history: [(date: Date, amount: Double)] = []
        
        // Day 1
        waterTracker.addWater(amount: 8)
        history.append((Date(), waterTracker.todayTotal))
        
        // Day 2
        simulateNextDay()
        waterTracker.checkAndResetIfNewDay()
        waterTracker.addWater(amount: 6)
        history.append((Date(), waterTracker.todayTotal))
        
        // Day 3
        simulateNextDay()
        waterTracker.checkAndResetIfNewDay()
        waterTracker.addWater(amount: 10)
        history.append((Date(), waterTracker.todayTotal))
        
        // Calculate weekly average
        let weeklyAverage = history.map { $0.amount }.reduce(0, +) / Double(history.count)
        XCTAssertEqual(weeklyAverage, 8.0, accuracy: 0.1)
    }
    
    // MARK: - Helper Methods
    
    private func simulateNextDay() {
        // Move the last reset date to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        UserDefaults.standard.set(yesterday, forKey: "lastWaterResetDate")
    }
}

// Test helpers for WaterTracker
extension WaterTracker {
    enum QuickAddAmount {
        case oneGlass
        case eightOunces
        case twoFiftyML
    }
    
    func quickAdd(_ amount: QuickAddAmount) {
        switch amount {
        case .oneGlass:
            addWater(amount: 1)
        case .eightOunces:
            if selectedUnit == .glasses {
                addWater(amount: 1) // Assuming 1 glass = 8oz
            } else {
                addWater(amount: 8)
            }
        case .twoFiftyML:
            if selectedUnit == .glasses {
                addWater(amount: 1) // Assuming rough conversion
            } else if selectedUnit == .milliliters {
                addWater(amount: 250)
            }
        }
    }
    
    func updateStreakIfGoalMet() {
        if todayTotal >= dailyGoal {
            incrementStreak()
        }
    }
    
    func resetStreak() {
        UserDefaults.standard.set(0, forKey: "waterStreak")
    }
}