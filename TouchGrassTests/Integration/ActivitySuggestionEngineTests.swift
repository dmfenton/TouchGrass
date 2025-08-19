import XCTest
@testable import Touch_Grass

class ActivitySuggestionEngineTests: XCTestCase {
    
    var engine: ActivitySuggestionEngine!
    var mockReminderManager: ReminderManager!
    
    override func setUp() {
        super.setUp()
        mockReminderManager = ReminderManager()
        engine = ActivitySuggestionEngine(reminderManager: mockReminderManager)
    }
    
    // MARK: - Time Constraint Tests
    
    func testMicroTimeWindow() {
        // Given: Only 1 minute available
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 1,
            weather: nil,
            timeSinceLastBreak: 3600,
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: Date().addingTimeInterval(60),
            currentStreak: 0,
            waterIntake: 4,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest micro activity
        XCTAssertLessThanOrEqual(suggestion.duration, 2)
        XCTAssertTrue(suggestion.type == "breathing" || suggestion.type == "exercise")
    }
    
    func testQuickTimeWindow() {
        // Given: 3 minutes available
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 3,
            weather: nil,
            timeSinceLastBreak: 3600,
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: Date().addingTimeInterval(180),
            currentStreak: 0,
            waterIntake: 4,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest quick activity
        XCTAssertLessThanOrEqual(suggestion.duration, 5)
        XCTAssertFalse(suggestion.type == "touchGrass")  // No time for outdoor
    }
    
    // MARK: - Weather Opportunity Tests
    
    func testPerfectWeatherOpportunity() {
        // Given: Perfect weather, haven't been outside, have time
        let perfectWeather = WeatherInfo(
            temperature: 68,
            condition: .sunny,
            isDaylight: true,
            description: "Sunny",
            humidity: 0.5,
            feelsLike: 68
        )
        
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 10,
            weather: perfectWeather,
            timeSinceLastBreak: 3600,
            todaysActivities: [],  // No outdoor today
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 6,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should strongly suggest outdoor
        XCTAssertEqual(suggestion.type, "touchGrass")
        XCTAssertTrue(suggestion.reason.contains("°F"))
        XCTAssertGreaterThan(suggestion.urgency, 0.8)
    }
    
    func testBadWeatherAvoidance() {
        // Given: Bad weather
        let badWeather = WeatherInfo(
            temperature: 35,
            condition: .rainy,
            isDaylight: true,
            description: "Heavy rain",
            humidity: 0.9,
            feelsLike: 30
        )
        
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 10,
            weather: badWeather,
            timeSinceLastBreak: 3600,
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 6,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should not suggest outdoor
        XCTAssertNotEqual(suggestion.type, "touchGrass")
    }
    
    // MARK: - Physical Needs Tests
    
    func testLongSittingDetection() {
        // Given: Been sitting for 2 hours
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 10,
            weather: nil,
            timeSinceLastBreak: 7200,  // 2 hours
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 6,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should prioritize movement
        XCTAssertTrue(suggestion.category == .physical || suggestion.category == .outdoor)
        XCTAssertTrue(suggestion.reason.contains("sitting") || suggestion.reason.contains("2"))
        XCTAssertGreaterThan(suggestion.urgency, 0.7)
    }
    
    func testHydrationNeed() {
        // Given: Low water intake
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 5,
            weather: nil,
            timeSinceLastBreak: 1800,  // Just 30 min
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 2,  // Very low
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest hydration
        XCTAssertEqual(suggestion.type, "water")
        XCTAssertTrue(suggestion.reason.contains("glasses"))
    }
    
    // MARK: - Meeting Density Tests
    
    func testHeavyMeetingDay() {
        // Given: Heavy meeting day with few breaks
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 8,
            weather: nil,
            timeSinceLastBreak: 3600,
            todaysActivities: [
                CompletedActivity(type: "breathing", category: .mental, completedAt: Date().addingTimeInterval(-7200), duration: 2)
            ],  // Only one short break
            meetingDensity: .heavy,
            nextMeeting: Date().addingTimeInterval(600),
            currentStreak: 0,
            waterIntake: 5,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should prioritize substantial break
        XCTAssertGreaterThanOrEqual(suggestion.duration, 5)
        XCTAssertTrue(suggestion.reason.contains("meeting") || suggestion.reason.contains("count"))
    }
    
    func testPreMeetingEnergizer() {
        // Given: Meeting in 5 minutes, been sitting long
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 5,
            weather: nil,
            timeSinceLastBreak: 6000,  // 100 minutes
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: Date().addingTimeInterval(300),  // 5 min
            currentStreak: 0,
            waterIntake: 5,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest quick energizer
        XCTAssertLessThanOrEqual(suggestion.duration, 3)
        XCTAssertEqual(suggestion.category, .physical)
        XCTAssertTrue(suggestion.reason.contains("meeting") || suggestion.reason.contains("boost"))
    }
    
    // MARK: - Time of Day Tests
    
    func testAfternoonSlump() {
        // Given: 2 PM (post-lunch slump time)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14  // 2 PM
        let afternoonTime = calendar.date(from: components)!
        
        let context = ActivityContext(
            currentTime: afternoonTime,
            availableMinutes: 10,
            weather: nil,
            timeSinceLastBreak: 3600,
            todaysActivities: [],
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 5,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest energizing activity
        XCTAssertTrue(suggestion.category == .physical || suggestion.type == "touchGrass")
        XCTAssertTrue(suggestion.reason.contains("slump") || suggestion.reason.contains("energy"))
    }
    
    func testEndOfDayLastChance() {
        // Given: 5 PM, haven't been outside, good weather
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 17  // 5 PM
        let eveningTime = calendar.date(from: components)!
        
        let goodWeather = WeatherInfo(
            temperature: 65,
            condition: .partlyCloudy,
            isDaylight: true,
            description: "Partly cloudy",
            humidity: 0.5,
            feelsLike: 65
        )
        
        let context = ActivityContext(
            currentTime: eveningTime,
            availableMinutes: 10,
            weather: goodWeather,
            timeSinceLastBreak: 3600,
            todaysActivities: [
                CompletedActivity(type: "exercise", category: .physical, completedAt: Date().addingTimeInterval(-14400), duration: 5)
            ],  // No outdoor today
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 7,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest last chance outdoor
        XCTAssertEqual(suggestion.type, "touchGrass")
        XCTAssertTrue(suggestion.reason.contains("last") || suggestion.reason.contains("ending"))
    }
    
    // MARK: - Variety and Balance Tests
    
    func testVarietyBalance() {
        // Given: Done only physical activities today
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 10,
            weather: nil,
            timeSinceLastBreak: 3600,
            todaysActivities: [
                CompletedActivity(type: "exercise", category: .physical, completedAt: Date().addingTimeInterval(-7200), duration: 5),
                CompletedActivity(type: "exercise", category: .physical, completedAt: Date().addingTimeInterval(-3600), duration: 3)
            ],
            meetingDensity: .normal,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 6,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest different category
        XCTAssertNotEqual(suggestion.category, .physical)
        XCTAssertTrue(suggestion.reason.contains("balance") || suggestion.reason.contains("haven't"))
    }
    
    // MARK: - Default Fallback Tests
    
    func testSmartDefaultShortTime() {
        // Given: Very short time, no special conditions
        let context = ActivityContext(
            currentTime: Date(),
            availableMinutes: 2,
            weather: nil,
            timeSinceLastBreak: 1800,  // Just 30 min
            todaysActivities: [],
            meetingDensity: .light,
            nextMeeting: nil,
            currentStreak: 0,
            waterIntake: 6,
            dailyWaterGoal: 8
        )
        
        // When: Getting suggestion
        let suggestion = engine.calculateBestActivity(for: context)
        
        // Then: Should suggest quick reset
        XCTAssertLessThanOrEqual(suggestion.duration, 2)
        XCTAssertTrue(suggestion.type == "breathing" || suggestion.title.contains("Reset"))
    }
}
