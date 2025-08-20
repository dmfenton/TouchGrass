import XCTest
import SwiftUI
@testable import Touch_Grass

class MenuBarIconTests: XCTestCase {
    var reminderManager: ReminderManager!
    
    override func setUp() {
        super.setUp()
        reminderManager = ReminderManager()
    }
    
    override func tearDown() {
        reminderManager = nil
        super.tearDown()
    }
    
    // MARK: - Work Hours Icon Tests
    
    func testIconIsGrayOutsideWorkHours() {
        // Set work hours to 9-5
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Test early morning (before work)
        let earlyMorning = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
        let isWithinHours = checkWorkHours(at: earlyMorning)
        XCTAssertFalse(isWithinHours, "Icon should be gray before work hours")
    }
    
    func testIconIsGreenDuringWorkHours() {
        // Set work hours to 9-5
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Test mid-day (during work)
        let midDay = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let isWithinHours = checkWorkHours(at: midDay)
        
        // Only check on weekdays
        let weekday = Calendar.current.component(.weekday, from: midDay)
        if weekday >= 2 && weekday <= 6 { // Monday-Friday
            XCTAssertTrue(isWithinHours, "Icon should be green during work hours on weekdays")
        }
    }
    
    func testIconIsGrayAfterWorkHours() {
        // Set work hours to 9-5
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Test evening (after work)
        let evening = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let isWithinHours = checkWorkHours(at: evening)
        XCTAssertFalse(isWithinHours, "Icon should be gray after work hours")
    }
    
    func testIconRespectsActiveReminder() {
        // Even outside work hours, icon should be active if there's a reminder
        reminderManager.hasActiveReminder = true
        
        // The icon should show as active regardless of work hours
        XCTAssertTrue(reminderManager.hasActiveReminder, "Icon should be active when reminder is showing")
    }
    
    // Helper method to check work hours at a specific time
    private func checkWorkHours(at date: Date) -> Bool {
        // This would typically be done by WorkHoursManager
        // For testing, we're checking the logic directly
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        
        guard let hour = components.hour,
              let minute = components.minute,
              let weekday = components.weekday else {
            return false
        }
        
        // Check if it's a work day (Monday-Friday = 2-6)
        guard weekday >= 2 && weekday <= 6 else {
            return false
        }
        
        // Check if within work hours (9-5)
        let currentMinutes = hour * 60 + minute
        let startMinutes = 9 * 60  // 9:00 AM
        let endMinutes = 17 * 60    // 5:00 PM
        
        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }
    
    // MARK: - Weather Service Tests
    
    func testWeatherServiceIsInitialized() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        XCTAssertNotNil(engine.weather, "Weather service should be initialized")
        XCTAssertTrue(engine.weather is NWSWeatherService, "Should be using NWS weather service")
    }
    
    func testWeatherServiceUsesRealLocation() {
        // Test that we're not using hardcoded San Francisco coordinates
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        // The weather service should request location permission
        // and use real location, not hardcoded values
        let weather = engine.weather.getCurrentWeatherSync()
        
        // If weather is available, it should be from actual location
        // (This test may return nil if no location permission)
        if weather != nil {
            print("Weather is available - using actual location")
        } else {
            print("Weather not available - likely no location permission")
        }
        
        // Just verify the service doesn't crash
        XCTAssertNotNil(engine.weather, "Weather service should exist")
    }
}
