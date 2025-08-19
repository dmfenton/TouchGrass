import XCTest
@testable import TouchGrass

class ActivitySuggestionEngineTests: XCTestCase {
    var engine: ActivitySuggestionEngine!
    var mockWeatherService: MockWeatherService!
    var mockActivityHistory: MockActivityHistory!
    var mockCalendar: MockCalendarManager!
    
    override func setUp() {
        super.setUp()
        mockWeatherService = MockWeatherService()
        mockActivityHistory = MockActivityHistory()
        mockCalendar = MockCalendarManager()
        
        engine = ActivitySuggestionEngine(
            weatherService: mockWeatherService,
            activityHistory: mockActivityHistory,
            calendarManager: mockCalendar
        )
    }
    
    // MARK: - Weather-Based Suggestions
    
    func testPerfectWeatherSuggestsTouchGrass() {
        // Given: Perfect weather and haven't been outside today
        mockWeatherService.currentWeather = WeatherData(
            temperature: 72,
            condition: .sunny,
            isDaylight: true
        )
        mockActivityHistory.todaysActivities = ["chin-tuck", "breathing"]
        
        // When: Getting suggestion at 10am
        let suggestion = engine.getSuggestion(at: DateComponents(hour: 10).date!)
        
        // Then: Should suggest Touch Grass
        XCTAssertEqual(suggestion.activityId, "touch-grass")
        XCTAssertEqual(suggestion.reason, "Beautiful day outside! 72°F and sunny")
    }
    
    func testBadWeatherAvoidsOutdoorActivities() {
        // Given: Rainy weather
        mockWeatherService.currentWeather = WeatherData(
            temperature: 45,
            condition: .rainy,
            isDaylight: true
        )
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should not suggest outdoor activity
        XCTAssertNotEqual(suggestion.activityId, "touch-grass")
        XCTAssertTrue(suggestion.isIndoor)
    }
    
    // MARK: - Time-Based Suggestions
    
    func testEarlyMorningSuggestsEnergizingActivity() {
        // Given: Early morning (7am)
        mockWeatherService.currentWeather = WeatherData(temperature: 60, condition: .cloudy, isDaylight: true)
        
        // When: Getting suggestion at 7am
        let suggestion = engine.getSuggestion(at: DateComponents(hour: 7).date!)
        
        // Then: Should suggest energizing activity
        XCTAssertTrue(["morning-stretches", "spinal-extension", "shoulder-rolls"].contains(suggestion.activityId))
        XCTAssertEqual(suggestion.reason, "Start your day with energizing movement")
    }
    
    func testPostLunchSlumpSuggestsMovement() {
        // Given: Post-lunch time (2pm)
        mockWeatherService.currentWeather = WeatherData(temperature: 65, condition: .cloudy, isDaylight: true)
        mockActivityHistory.lastActivityTime = Date().addingTimeInterval(-7200) // 2 hours ago
        
        // When: Getting suggestion at 2pm
        let suggestion = engine.getSuggestion(at: DateComponents(hour: 14).date!)
        
        // Then: Should suggest movement to combat afternoon slump
        XCTAssertTrue(suggestion.category == .movement || suggestion.activityId == "touch-grass")
        XCTAssertContains(suggestion.reason, "energiz")
    }
    
    func testEveningWindDownSuggestsCalming() {
        // Given: Evening time (5:30pm) after stressful day
        mockCalendar.todaysMeetingCount = 6
        
        // When: Getting suggestion at 5:30pm
        let suggestion = engine.getSuggestion(at: DateComponents(hour: 17, minute: 30).date!)
        
        // Then: Should suggest calming activity
        XCTAssertTrue(["deep-breathing", "meditation", "gentle-stretches"].contains(suggestion.activityId))
        XCTAssertContains(suggestion.reason, "wind down")
    }
    
    // MARK: - Physical Need Based
    
    func testLongSittingSuggestsMovement() {
        // Given: Sitting for 2+ hours
        mockActivityHistory.lastMovementTime = Date().addingTimeInterval(-8000) // 2.2 hours ago
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should prioritize movement
        XCTAssertTrue(suggestion.category == .movement || suggestion.category == .stretch)
        XCTAssertContains(suggestion.reason, "time to move")
    }
    
    func testPostureTimeSuggestsCorrection() {
        // Given: Haven't done posture exercises today and sitting for 90+ min
        mockActivityHistory.todaysActivities = ["deep-breathing", "eye-exercise"]
        mockActivityHistory.lastPostureExercise = Date().addingTimeInterval(-5400) // 90 min ago
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should suggest posture correction
        XCTAssertTrue(["chin-tuck", "scapular-retraction", "back-core"].contains(suggestion.activityId))
    }
    
    // MARK: - Variety and Balance
    
    func testSuggestsVarietyInActivities() {
        // Given: Only physical activities done today
        mockActivityHistory.todaysActivities = ["chin-tuck", "shoulder-rolls", "hip-rotations"]
        mockWeatherService.currentWeather = WeatherData(temperature: 60, condition: .cloudy, isDaylight: true)
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should suggest mental/calming activity for balance
        XCTAssertTrue(["deep-breathing", "meditation", "eye-exercise"].contains(suggestion.activityId))
        XCTAssertContains(suggestion.reason, "balance")
    }
    
    func testAvoidsRepeatingSameActivity() {
        // Given: Just did chin tucks
        mockActivityHistory.lastActivity = "chin-tuck"
        mockActivityHistory.lastActivityTime = Date().addingTimeInterval(-1800) // 30 min ago
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should not suggest chin tucks again
        XCTAssertNotEqual(suggestion.activityId, "chin-tuck")
    }
    
    // MARK: - Time Constraints
    
    func testShortTimeSuggestsQuickActivity() {
        // Given: Only 2 minutes available
        mockCalendar.timeUntilNextMeeting = 120 // seconds
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should suggest quick activity
        XCTAssertTrue(suggestion.duration <= 120)
        XCTAssertTrue(["quick-reset", "deep-breathing", "eye-exercise"].contains(suggestion.activityId))
    }
    
    func testLongTimeSuggestsFullRoutine() {
        // Given: 10+ minutes available
        mockCalendar.timeUntilNextMeeting = 600 // seconds
        mockWeatherService.currentWeather = WeatherData(temperature: 70, condition: .sunny, isDaylight: true)
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Can suggest longer activities
        XCTAssertTrue(["touch-grass", "back-core", "upper-body", "lower-body"].contains(suggestion.activityId))
    }
    
    // MARK: - Scoring System
    
    func testScoringPrefersLeastRecentActivity() {
        // Given: Two activities, one done 3 days ago, one done yesterday
        mockActivityHistory.activityLastDone = [
            "chin-tuck": Date().addingTimeInterval(-86400), // 1 day ago
            "shoulder-rolls": Date().addingTimeInterval(-259200) // 3 days ago
        ]
        
        // When: Getting suggestion (with no other strong factors)
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should prefer the older activity
        XCTAssertEqual(suggestion.activityId, "shoulder-rolls")
    }
    
    // MARK: - Edge Cases
    
    func testHandlesNoWeatherData() {
        // Given: Weather service fails
        mockWeatherService.currentWeather = nil
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should still provide indoor suggestion
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion.isIndoor)
    }
    
    func testHandlesFirstTimeUser() {
        // Given: No activity history
        mockActivityHistory.todaysActivities = []
        mockActivityHistory.activityLastDone = [:]
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should provide gentle starter suggestion
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(["quick-reset", "deep-breathing", "chin-tuck"].contains(suggestion.activityId))
    }
    
    func testProvidesFallbackSuggestion() {
        // Given: All edge case conditions
        mockWeatherService.currentWeather = nil
        mockActivityHistory.todaysActivities = nil
        mockCalendar.timeUntilNextMeeting = nil
        
        // When: Getting suggestion
        let suggestion = engine.getSuggestion(at: Date())
        
        // Then: Should still provide a valid suggestion
        XCTAssertNotNil(suggestion)
        XCTAssertNotNil(suggestion.activityId)
        XCTAssertNotNil(suggestion.reason)
    }
}

// MARK: - Mock Classes

class MockWeatherService: WeatherServiceProtocol {
    var currentWeather: WeatherData?
    
    func getCurrentWeather() -> WeatherData? {
        return currentWeather
    }
}

class MockActivityHistory: ActivityHistoryProtocol {
    var todaysActivities: [String]?
    var lastActivity: String?
    var lastActivityTime: Date?
    var lastMovementTime: Date?
    var lastPostureExercise: Date?
    var activityLastDone: [String: Date] = [:]
    
    func getActivitiesToday() -> [String] {
        return todaysActivities ?? []
    }
    
    func getLastActivityTime() -> Date? {
        return lastActivityTime
    }
    
    func getTimeForActivity(_ activityId: String) -> Date? {
        return activityLastDone[activityId]
    }
}

// MARK: - Helper Extensions for Tests

extension DateComponents {
    var date: Date? {
        return Calendar.current.date(from: self)
    }
}

extension XCTestCase {
    func XCTAssertContains(_ string: String, _ substring: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(string.lowercased().contains(substring.lowercased()), 
                     "\"\(string)\" does not contain \"\(substring)\"", 
                     file: file, line: line)
    }
}

// MARK: - Data Models for Testing

struct WeatherData {
    let temperature: Int // Fahrenheit
    let condition: WeatherCondition
    let isDaylight: Bool
}

enum WeatherCondition {
    case sunny, cloudy, rainy, snowy
}

struct ActivitySuggestion {
    let activityId: String
    let reason: String
    let category: ActivityCategory
    let duration: Int // seconds
    let isIndoor: Bool
}

enum ActivityCategory {
    case movement, stretch, breathing, meditation, outdoor, posture
}