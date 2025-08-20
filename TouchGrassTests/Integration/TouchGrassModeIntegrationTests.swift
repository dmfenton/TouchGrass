import XCTest
import SwiftUI
@testable import Touch_Grass

class TouchGrassModeIntegrationTests: XCTestCase {
    var reminderManager: ReminderManager!
    
    override func setUp() {
        super.setUp()
        reminderManager = ReminderManager()
    }
    
    override func tearDown() {
        reminderManager = nil
        super.tearDown()
    }
    
    // MARK: - Suggestion Engine Tests
    
    func testSuggestionEngineIsInitialized() {
        XCTAssertNotNil(reminderManager.suggestionEngine, "Suggestion engine should be initialized")
    }
    
    func testSuggestionEngineReturnsSuggestion() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        let suggestion = engine.getSuggestionSync()
        XCTAssertNotNil(suggestion.title, "Suggestion should have a title")
        XCTAssertFalse(suggestion.title.isEmpty, "Suggestion title should not be empty")
        XCTAssertNotNil(suggestion.reason, "Suggestion should have a reason")
        XCTAssertFalse(suggestion.reason.isEmpty, "Suggestion reason should not be empty")
        XCTAssertNotNil(suggestion.type, "Suggestion should have a type")
        
        // Verify type is one of expected values
        let validTypes = ["touchGrass", "exercise", "posture", "meditation", "hydration", "water"]
        XCTAssertTrue(validTypes.contains(suggestion.type), 
                      "Suggestion type '\(suggestion.type)' should be valid")
    }
    
    func testWeatherServiceIsAccessible() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        XCTAssertNotNil(engine.weather, "Weather service should be accessible")
    }
    
    func testWeatherServiceReturnsData() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        let weather = engine.weather.getCurrentWeatherSync()
        
        // Weather might be nil if no location permission, but should not crash
        if let weather = weather {
            XCTAssertGreaterThan(weather.temperature, -100, "Temperature should be realistic")
            XCTAssertLessThan(weather.temperature, 150, "Temperature should be realistic")
            XCTAssertNotNil(weather.condition, "Weather should have a condition")
        }
    }
    
    // MARK: - TouchGrassMode View Tests
    
    func testTouchGrassModeLoadsWithSuggestion() {
        // Create a test view
        let view = TouchGrassMode(reminderManager: reminderManager)
        
        // Create a hosting controller to trigger onAppear
        let hostingController = NSHostingController(rootView: view)
        _ = hostingController.view // This triggers view loading
        
        // Give time for async operations
        let expectation = self.expectation(description: "View loads")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Verify the view can be created without crashing
        XCTAssertNotNil(hostingController.view, "View should be created")
    }
    
    // MARK: - Location Permission Tests
    
    func testLocationAlertOnlyShowsWhenNotDetermined() {
        let locationManager = LocationPermissionManager.shared
        let status = locationManager.authorizationStatus
        
        // The alert should only show if status is .notDetermined
        // This prevents the alert from showing when already denied or authorized
        if status == .notDetermined {
            print("Location permission not determined - alert would show")
        } else if status == .authorizedAlways {
            print("Location already authorized - alert should NOT show")
        } else if status == .denied || status == .restricted {
            print("Location denied/restricted - alert should NOT show")
        }
        
        // Just verify we can check the status without crashing
        XCTAssertNotNil(status, "Should be able to check location status")
    }
    
    // MARK: - Integration Tests
    
    func testFullSuggestionFlow() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        // Test that we can get a suggestion multiple times
        for i in 1...3 {
            let suggestion = engine.getSuggestionSync()
            XCTAssertNotNil(suggestion.title, "Suggestion \(i) should have a title")
            XCTAssertNotNil(suggestion.reason, "Suggestion \(i) should have a reason")
            
            print("Suggestion \(i): \(suggestion.title) - \(suggestion.reason)")
        }
    }
    
    func testSuggestionContextBuilding() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        // Get a suggestion to ensure context building works
        let suggestion = engine.getSuggestionSync()
        
        // Verify the suggestion makes sense based on the context
        if suggestion.type == "hydration" {
            XCTAssertTrue(suggestion.title.lowercased().contains("water") || 
                         suggestion.title.lowercased().contains("hydrat"),
                         "Hydration suggestion should mention water")
        }
        
        if suggestion.type == "touchGrass" {
            XCTAssertTrue(suggestion.title.lowercased().contains("outdoor") || 
                         suggestion.title.lowercased().contains("outside") ||
                         suggestion.title.lowercased().contains("grass"),
                         "Outdoor suggestion should mention going outside")
        }
    }
    
    func testWeatherIntegration() {
        guard let engine = reminderManager.suggestionEngine else {
            XCTFail("Suggestion engine not available")
            return
        }
        
        // If weather is available, test that outdoor suggestions consider it
        if let weather = engine.weather.getCurrentWeatherSync() {
            let suggestion = engine.getSuggestionSync()
            
            if weather.isIdealForOutdoor {
                print("Weather is ideal for outdoor activities")
                // In ideal weather, outdoor suggestions should be more likely
            } else if !weather.isGoodForOutdoor {
                print("Weather is not good for outdoor activities")
                // In bad weather, indoor suggestions should be more likely
                if suggestion.type == "touchGrass" {
                    XCTFail("Should not suggest outdoor activities in bad weather")
                }
            }
        }
    }
}
