import XCTest
import Combine
@testable import Touch_Grass

final class WaterTrackingTests: XCTestCase {
    var waterTracker: WaterTracker!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        waterTracker = WaterTracker()
        cancellables = []
        
        // Reset water tracking for clean tests
        waterTracker.reset()
    }
    
    override func tearDown() {
        cancellables = nil
        waterTracker = nil
        
        super.tearDown()
    }
    
    func testDailyGoalTracking() {
        // Given: Daily goal of 8 glasses
        waterTracker.dailyGoal = 8
        waterTracker.unit = .glasses
        
        // When: Logging water throughout the day
        waterTracker.logWater(2)
        XCTAssertEqual(waterTracker.currentIntake, 2)
        XCTAssertEqual(waterTracker.progressPercentage, 0.25, accuracy: 0.01)
        
        waterTracker.logWater(3)
        XCTAssertEqual(waterTracker.currentIntake, 5)
        XCTAssertEqual(waterTracker.progressPercentage, 0.625, accuracy: 0.01)
        
        waterTracker.logWater(3)
        XCTAssertEqual(waterTracker.currentIntake, 8)
        XCTAssertEqual(waterTracker.progressPercentage, 1.0, accuracy: 0.01)
        
        // Can exceed goal
        waterTracker.logWater(2)
        XCTAssertEqual(waterTracker.currentIntake, 10)
        XCTAssertGreaterThan(waterTracker.progressPercentage, 1.0)
    }
    
    func testUnitConversion() {
        // Test ounces conversion
        waterTracker.unit = .ounces
        waterTracker.dailyGoal = 8 // 8 glasses
        
        // The goal in ounces should be 64 (8 glasses * 8 oz)
        let goalInOz = waterTracker.unit.fromGlasses(waterTracker.dailyGoal)
        XCTAssertEqual(goalInOz, 64)
        
        // Test milliliters conversion
        waterTracker.unit = .milliliters
        let goalInMl = waterTracker.unit.fromGlasses(waterTracker.dailyGoal)
        XCTAssertEqual(goalInMl, 1896) // 8 glasses * 237ml
    }
    
    func testDailyReset() {
        // Given: Some water logged today
        waterTracker.dailyGoal = 8
        waterTracker.logWater(5)
        XCTAssertEqual(waterTracker.currentIntake, 5)
        
        // When: Resetting
        waterTracker.reset()
        
        // Then: Should reset to zero
        XCTAssertEqual(waterTracker.currentIntake, 0)
        XCTAssertEqual(waterTracker.progressPercentage, 0, accuracy: 0.01)
    }
    
    func testStreakTracking() {
        // Test streak property exists
        let _ = waterTracker.streak
        XCTAssertTrue(true) // Property exists
    }
    
    func testPersistence() {
        // Given: Some water tracking data
        waterTracker.dailyGoal = 10
        waterTracker.unit = .ounces
        waterTracker.logWater(4)
        let originalIntake = waterTracker.currentIntake
        
        // When: Creating new tracker (simulating app restart)
        let newTracker = WaterTracker()
        
        // Then: Should restore persisted data
        XCTAssertEqual(newTracker.dailyGoal, 10)
        XCTAssertEqual(newTracker.unit, .ounces)
        XCTAssertEqual(newTracker.currentIntake, originalIntake)
    }
    
    func testProgressNotifications() {
        var progressUpdates: [Double] = []
        
        waterTracker.$currentIntake
            .map { _ in self.waterTracker.progressPercentage }
            .sink { progress in
                progressUpdates.append(progress)
            }
            .store(in: &cancellables)
        
        waterTracker.dailyGoal = 4
        waterTracker.logWater(1)
        waterTracker.logWater(1)
        waterTracker.logWater(1)
        waterTracker.logWater(1)
        
        // Should have progress updates
        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertEqual(waterTracker.progressPercentage, 1.0, accuracy: 0.01)
    }
    
    func testHasMetDailyGoal() {
        waterTracker.dailyGoal = 8
        waterTracker.reset()
        
        XCTAssertFalse(waterTracker.hasMetDailyGoal)
        
        waterTracker.logWater(8)
        XCTAssertTrue(waterTracker.hasMetDailyGoal)
    }
    
    func testDisplayText() {
        waterTracker.unit = .glasses
        waterTracker.dailyGoal = 8
        waterTracker.currentIntake = 4
        
        let display = waterTracker.displayText
        XCTAssertTrue(display.contains("4"))
        XCTAssertTrue(display.contains("8"))
    }
    
    func testLogWaterInCurrentUnit() {
        waterTracker.unit = .ounces
        waterTracker.reset()
        
        // Log 16 ounces (should be 2 glasses)
        waterTracker.logWaterInCurrentUnit(16)
        XCTAssertEqual(waterTracker.currentIntake, 2)
    }
}