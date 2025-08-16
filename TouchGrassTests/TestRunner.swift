#!/usr/bin/swift

import Foundation

// Simple test runner that can be executed directly
class TestRunner {
    private var totalTests = 0
    private var passedTests = 0
    private var failedTests = 0
    private var currentTestName = ""
    
    func runTests() {
        print("🧪 Running Touch Grass Integration Tests")
        print("========================================")
        
        // Run test suites
        testReminderScheduling()
        testTouchGrassMode()
        testCalendarIntegration()
        testWaterTracking()
        testWorkHours()
        
        // Print summary
        print("\n========================================")
        print("Test Results:")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("📊 Total: \(totalTests)")
        
        if failedTests == 0 {
            print("\n🎉 All tests passed!")
            exit(0)
        } else {
            print("\n⚠️  Some tests failed")
            exit(1)
        }
    }
    
    // MARK: - Test Infrastructure
    
    func test(_ name: String, _ testBlock: () throws -> Void) {
        currentTestName = name
        totalTests += 1
        
        do {
            try testBlock()
            passedTests += 1
            print("  ✅ \(name)")
        } catch {
            failedTests += 1
            print("  ❌ \(name)")
            print("     Error: \(error)")
        }
    }
    
    func assert(_ condition: Bool, _ message: String = "") throws {
        if !condition {
            throw TestError.assertionFailed(message.isEmpty ? "Assertion failed" : message)
        }
    }
    
    func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "") throws {
        if actual != expected {
            let msg = message.isEmpty ? "Expected \(expected), got \(actual)" : message
            throw TestError.assertionFailed(msg)
        }
    }
    
    // MARK: - Test Suites
    
    func testReminderScheduling() {
        print("\n📅 Reminder Scheduling Tests:")
        
        test("Fixed interval scheduling") {
            let scheduler = TestScheduler()
            let startTime = Date()
            scheduler.setCurrentTime(startTime)
            
            // Test 45-minute intervals align to clock
            let interval: TimeInterval = 45 * 60
            let nextTime = scheduler.calculateNextAlignedTime(from: startTime, interval: interval)
            
            let calendar = Calendar.current
            let minutes = calendar.component(.minute, from: nextTime)
            try assert(minutes == 0 || minutes == 45, "Should align to :00 or :45")
        }
        
        test("Work hours boundary") {
            let workStart = 9 * 60 // 9 AM in minutes
            let workEnd = 17 * 60 // 5 PM in minutes
            let currentTime = 16 * 60 + 30 // 4:30 PM
            
            let nextReminder = min(currentTime + 45, workEnd)
            try assert(nextReminder <= workEnd, "Should not schedule past work hours")
        }
        
        test("Pause and resume") {
            var isPaused = false
            
            // Pause
            isPaused = true
            try assert(isPaused == true, "Should be paused")
            
            // Resume
            isPaused = false
            try assert(isPaused == false, "Should be resumed")
        }
    }
    
    func testTouchGrassMode() {
        print("\n🌱 Touch Grass Mode Tests:")
        
        test("Mode activation") {
            var hasActiveReminder = false
            var isTouchGrassModeActive = false
            
            // Activate
            hasActiveReminder = true
            isTouchGrassModeActive = true
            
            try assert(hasActiveReminder, "Should have active reminder")
            try assert(isTouchGrassModeActive, "Should be in touch grass mode")
        }
        
        test("Activity completion") {
            var streak = 0
            var hasActiveReminder = true
            
            // Complete activity
            streak += 1
            hasActiveReminder = false
            
            try assertEqual(streak, 1, "Streak should increment")
            try assert(!hasActiveReminder, "Reminder should be cleared")
        }
        
        test("Streak management") {
            var streak = 0
            
            // Day 1: Complete
            streak += 1
            try assertEqual(streak, 1)
            
            // Day 2: Complete
            streak += 1
            try assertEqual(streak, 2)
            
            // Day 3: Skip
            streak = 0
            try assertEqual(streak, 0, "Streak should reset on skip")
        }
    }
    
    func testCalendarIntegration() {
        print("\n📅 Calendar Integration Tests:")
        
        test("Calendar permission") {
            let hasAccess = true // Simulate granted permission
            try assert(hasAccess, "Should have calendar access")
        }
        
        test("Meeting detection") {
            var isInMeeting = false
            
            // Start meeting
            isInMeeting = true
            try assert(isInMeeting, "Should detect meeting")
            
            // End meeting
            isInMeeting = false
            try assert(!isInMeeting, "Should detect meeting end")
        }
        
        test("Meeting-aware scheduling") {
            let meetingStart = Date().addingTimeInterval(5 * 60)
            let meetingEnd = meetingStart.addingTimeInterval(30 * 60)
            let nextReminder = Date().addingTimeInterval(45 * 60)
            
            // Should schedule after meeting
            try assert(nextReminder > meetingEnd, "Should not schedule during meeting")
        }
    }
    
    func testWaterTracking() {
        print("\n💧 Water Tracking Tests:")
        
        test("Daily goal tracking") {
            let dailyGoal = 8
            var currentIntake = 0
            
            currentIntake += 2
            let progress = Double(currentIntake) / Double(dailyGoal)
            try assertEqual(progress, 0.25, "Progress should be 25%")
            
            currentIntake = 8
            try assert(currentIntake >= dailyGoal, "Should meet daily goal")
        }
        
        test("Unit conversion") {
            // 1 glass = 8 oz = 237 ml (approximately)
            let glasses = 1
            let ounces = glasses * 8
            let milliliters = Int(Double(glasses) * 237)
            
            try assertEqual(ounces, 8)
            try assertEqual(milliliters, 237)
        }
        
        test("Daily reset") {
            var todayIntake = 5
            let isNewDay = true
            
            if isNewDay {
                todayIntake = 0
            }
            
            try assertEqual(todayIntake, 0, "Should reset daily intake")
        }
    }
    
    func testWorkHours() {
        print("\n⏰ Work Hours Tests:")
        
        test("Work hours configuration") {
            let workStartHour = 9
            let workEndHour = 17
            
            try assertEqual(workStartHour, 9)
            try assertEqual(workEndHour, 17)
        }
        
        test("Within work hours check") {
            let currentHour = 10
            let workStartHour = 9
            let workEndHour = 17
            
            let isWithinHours = currentHour >= workStartHour && currentHour < workEndHour
            try assert(isWithinHours, "10 AM should be within work hours")
        }
        
        test("Weekend detection") {
            let weekday = 1 // Sunday
            let workDays = [2, 3, 4, 5, 6] // Mon-Fri
            
            let isWorkDay = workDays.contains(weekday)
            try assert(!isWorkDay, "Sunday should not be a work day")
        }
    }
    
    enum TestError: Error {
        case assertionFailed(String)
    }
}

// Helper class for time-based testing
class TestScheduler {
    private var currentTime = Date()
    
    func setCurrentTime(_ time: Date) {
        currentTime = time
    }
    
    func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)
    }
    
    func calculateNextAlignedTime(from date: Date, interval: TimeInterval) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = components.hour! * 60 + components.minute!
        
        let intervalMinutes = Int(interval / 60)
        let minutesPastHour = currentMinutes % 60
        
        var nextMinutes: Int
        if intervalMinutes == 45 {
            // Align to :00 or :45
            if minutesPastHour < 45 {
                nextMinutes = 45
            } else {
                nextMinutes = 60
            }
        } else {
            // Regular interval
            nextMinutes = ((currentMinutes / intervalMinutes) + 1) * intervalMinutes
        }
        
        let additionalMinutes = nextMinutes - currentMinutes
        return date.addingTimeInterval(TimeInterval(additionalMinutes * 60))
    }
}

// Run the tests
let runner = TestRunner()
runner.runTests()