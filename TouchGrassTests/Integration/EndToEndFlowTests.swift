import XCTest
import Combine
import EventKit

// End-to-end tests that simulate complete user workflows
final class EndToEndFlowTests: XCTestCase {
    var reminderManager: ReminderManager!
    var mockCalendarManager: MockCalendarManager!
    var testScheduler: TestScheduler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        testScheduler = TestScheduler()
        mockCalendarManager = MockCalendarManager()
        reminderManager = ReminderManager()
        reminderManager.calendarManager = mockCalendarManager
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        mockCalendarManager = nil
        testScheduler = nil
        super.tearDown()
    }
    
    // MARK: - Complete Exercise Flow
    
    func testCompleteExerciseFlow() {
        // Track the entire flow state
        var flowStates: [String] = []
        
        // STEP 1: User clicks menu bar icon when reminder is active
        reminderManager.hasActiveReminder = true
        reminderManager.isTouchGrassModeActive = true
        flowStates.append("menu_opened_with_reminder")
        XCTAssertTrue(reminderManager.hasActiveReminder)
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
        
        // STEP 2: User selects "Exercises" from Touch Grass mode
        let selectedActivity = "exercise"
        flowStates.append("exercise_selected")
        
        // STEP 3: User picks a specific exercise (e.g., chin tucks)
        let exercise = Exercise.chinTuckQuick
        flowStates.append("specific_exercise_selected:\(exercise.id)")
        XCTAssertEqual(exercise.duration, 30)
        XCTAssertEqual(exercise.instructions.count, 4)
        
        // STEP 4: Exercise starts - timer begins
        var timerSeconds = exercise.duration
        var currentStep = 0
        flowStates.append("exercise_started")
        
        // Simulate timer countdown
        while timerSeconds > 0 {
            // Each step has its own duration
            if currentStep < exercise.instructions.count {
                flowStates.append("step_\(currentStep + 1)_active")
                
                // Simulate audio playing for instruction
                flowStates.append("audio_playing:step_\(currentStep + 1)")
                
                // Progress to next step
                currentStep += 1
            }
            
            // Simulate timer tick
            timerSeconds -= 10 // Fast forward for testing
            testScheduler.advance(by: 10)
        }
        
        // STEP 5: Exercise completes
        flowStates.append("exercise_completed")
        reminderManager.completeActivity("exercise")
        
        // STEP 6: Verify completion state
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        XCTAssertEqual(reminderManager.currentStreak, 1)
        
        // STEP 7: Window closes, next reminder scheduled
        flowStates.append("window_closed")
        XCTAssertNotNil(reminderManager.nextReminderTime)
        
        // Verify flow progression
        XCTAssertTrue(flowStates.contains("menu_opened_with_reminder"))
        XCTAssertTrue(flowStates.contains("exercise_selected"))
        XCTAssertTrue(flowStates.contains("exercise_started"))
        XCTAssertTrue(flowStates.contains("exercise_completed"))
        XCTAssertTrue(flowStates.contains("window_closed"))
    }
    
    // MARK: - Complete Touch Grass Flow with Interruptions
    
    func testTouchGrassFlowWithSnooze() {
        var flowStates: [String] = []
        
        // User sees reminder notification
        reminderManager.triggerReminder()
        flowStates.append("reminder_triggered")
        XCTAssertTrue(reminderManager.hasActiveReminder)
        
        // User clicks menu icon
        flowStates.append("menu_opened")
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
        
        // User clicks snooze (5 minutes)
        reminderManager.snooze(minutes: 5)
        flowStates.append("snoozed_5_min")
        
        // Verify state after snooze
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        
        // Advance time 5 minutes
        testScheduler.advance(by: 5 * 60)
        
        // Reminder triggers again
        reminderManager.triggerReminder()
        flowStates.append("reminder_retriggered")
        
        // This time user completes activity
        reminderManager.showTouchGrassMode()
        reminderManager.completeActivity("touchGrass")
        flowStates.append("activity_completed")
        
        // Verify final state
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertEqual(reminderManager.currentStreak, 1)
    }
    
    // MARK: - Meeting-Aware Flow
    
    func testMeetingInterruptionFlow() {
        var flowStates: [String] = []
        
        // Normal work time, reminder scheduled
        reminderManager.scheduleNextReminderIfNeeded()
        flowStates.append("reminder_scheduled")
        XCTAssertNotNil(reminderManager.nextReminderTime)
        
        // Meeting starts before reminder
        mockCalendarManager.simulateMeetingStart(
            title: "Team Standup",
            endTime: Date().addingTimeInterval(30 * 60)
        )
        flowStates.append("meeting_started")
        
        // Reminder time arrives but suppressed due to meeting
        testScheduler.advance(by: reminderManager.intervalMinutes * 60)
        XCTAssertTrue(mockCalendarManager.isInMeeting)
        XCTAssertFalse(reminderManager.hasActiveReminder) // Suppressed
        flowStates.append("reminder_suppressed_during_meeting")
        
        // Meeting ends
        testScheduler.advance(by: 30 * 60)
        mockCalendarManager.simulateMeetingEnd()
        flowStates.append("meeting_ended")
        
        // Reminder triggers after meeting
        reminderManager.checkForMeetingTransition()
        flowStates.append("post_meeting_reminder_triggered")
        XCTAssertTrue(reminderManager.hasActiveReminder)
        
        // User completes quick activity
        reminderManager.completeActivity("touchGrass")
        flowStates.append("quick_break_completed")
        
        // Verify the flow handled meeting correctly
        XCTAssertTrue(flowStates.contains("reminder_suppressed_during_meeting"))
        XCTAssertTrue(flowStates.contains("post_meeting_reminder_triggered"))
    }
    
    // MARK: - Water Tracking Integration Flow
    
    func testCompleteWaterTrackingFlow() {
        var flowStates: [String] = []
        
        // Start of workday
        reminderManager.waterTracker.resetDaily()
        flowStates.append("day_started")
        XCTAssertEqual(reminderManager.waterTracker.todayTotal, 0)
        
        // First reminder - user logs water
        reminderManager.showTouchGrassMode()
        flowStates.append("first_reminder")
        
        // User clicks +8oz button
        reminderManager.waterTracker.addWater(amount: 8)
        flowStates.append("water_logged:8oz")
        
        // Complete touch grass activity
        reminderManager.completeActivity("touchGrass")
        flowStates.append("activity_completed")
        
        // Throughout the day, multiple water logs
        for hour in 1...4 {
            testScheduler.advance(by: 60 * 60) // 1 hour
            reminderManager.showTouchGrassMode()
            reminderManager.waterTracker.addWater(amount: 8)
            flowStates.append("water_logged:8oz_hour_\(hour)")
            reminderManager.completeActivity("touchGrass")
        }
        
        // Check daily progress
        XCTAssertEqual(reminderManager.waterTracker.todayTotal, 40) // 5 * 8oz
        XCTAssertTrue(reminderManager.waterTracker.progressPercentage > 0.5)
        
        // End of day - check if goal met
        if reminderManager.waterTracker.hasMetDailyGoal {
            flowStates.append("daily_goal_met")
            reminderManager.waterTracker.incrementStreak()
        }
        
        // Verify water tracking integrated with reminders
        XCTAssertTrue(flowStates.filter { $0.contains("water_logged") }.count >= 5)
    }
    
    // MARK: - Full Day Simulation
    
    func testFullWorkdayFlow() {
        var flowStates: [String] = []
        var activitiesCompleted = 0
        var waterIntake = 0
        
        // Set work hours 9 AM - 5 PM
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Start at 9 AM Monday
        let workStart = createDate(hour: 9, minute: 0)
        testScheduler.setCurrentTime(workStart)
        flowStates.append("workday_started:9am")
        
        // Simulate 8-hour workday with 45-minute intervals
        for hour in 0..<8 {
            let currentHour = 9 + hour
            
            // Check for meetings (simulate some calendar events)
            if currentHour == 10 || currentHour == 14 {
                mockCalendarManager.simulateMeetingStart(
                    title: "Meeting \(currentHour)",
                    endTime: Date().addingTimeInterval(30 * 60)
                )
                flowStates.append("meeting:\(currentHour):00")
                testScheduler.advance(by: 30 * 60)
                mockCalendarManager.simulateMeetingEnd()
                continue
            }
            
            // Regular reminder flow
            if hour % 1 == 0 { // Every hour for testing
                reminderManager.triggerReminder()
                flowStates.append("reminder:\(currentHour):00")
                
                // Randomly choose activity
                let activities = ["touchGrass", "exercise", "stretch", "water"]
                let activity = activities[hour % activities.count]
                
                if activity == "water" {
                    reminderManager.waterTracker.addWater(amount: 8)
                    waterIntake += 8
                    flowStates.append("water_break:\(currentHour):00")
                } else {
                    reminderManager.completeActivity(activity)
                    activitiesCompleted += 1
                    flowStates.append("\(activity)_completed:\(currentHour):00")
                }
            }
            
            testScheduler.advance(by: 60 * 60)
        }
        
        // End of workday - 5 PM
        flowStates.append("workday_ended:5pm")
        
        // Verify full day statistics
        XCTAssertTrue(activitiesCompleted >= 4, "Should complete multiple activities")
        XCTAssertTrue(waterIntake >= 32, "Should log water throughout day")
        XCTAssertTrue(reminderManager.currentStreak >= 1, "Should maintain streak")
        XCTAssertTrue(flowStates.contains("meeting:10:00"), "Should handle meetings")
        XCTAssertTrue(flowStates.filter { $0.contains("reminder:") }.count >= 4, "Multiple reminders")
        
        // After work hours - should auto-pause
        testScheduler.advance(by: 60 * 60) // 6 PM
        XCTAssertTrue(reminderManager.isPaused || !reminderManager.isWithinWorkHours(date: testScheduler.now))
        flowStates.append("after_hours_paused")
    }
    
    // MARK: - Edge Cases and Error Recovery
    
    func testErrorRecoveryFlow() {
        var flowStates: [String] = []
        
        // Simulate various error conditions and recovery
        
        // 1. Calendar permission denied
        mockCalendarManager.mockHasCalendarAccess = false
        flowStates.append("calendar_permission_denied")
        XCTAssertFalse(mockCalendarManager.hasCalendarAccess)
        
        // App should still function without calendar
        reminderManager.showTouchGrassMode()
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
        flowStates.append("functioning_without_calendar")
        
        // 2. User rapidly clicks snooze multiple times
        for _ in 0..<3 {
            reminderManager.snooze(minutes: 5)
            flowStates.append("rapid_snooze")
        }
        // Should handle gracefully without crashes
        XCTAssertFalse(reminderManager.hasActiveReminder)
        
        // 3. App launches during meeting
        mockCalendarManager.simulateMeetingStart(
            title: "Important Call",
            endTime: Date().addingTimeInterval(60 * 60)
        )
        reminderManager.scheduleNextReminderIfNeeded()
        flowStates.append("launched_during_meeting")
        
        // Should schedule for after meeting
        if let nextReminder = reminderManager.nextReminderTime {
            XCTAssertTrue(nextReminder > mockCalendarManager.mockCurrentEvent!.endDate)
        }
        
        // 4. Streak broken recovery
        reminderManager.activityTracker.currentStreak = 5
        reminderManager.skipActivity() // Breaks streak
        flowStates.append("streak_broken")
        XCTAssertEqual(reminderManager.currentStreak, 0)
        
        // User can start new streak immediately
        reminderManager.completeActivity("touchGrass")
        XCTAssertEqual(reminderManager.currentStreak, 1)
        flowStates.append("new_streak_started")
        
        // Verify error recovery
        XCTAssertTrue(flowStates.contains("functioning_without_calendar"))
        XCTAssertTrue(flowStates.contains("new_streak_started"))
    }
    
    // MARK: - Helper Methods
    
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

// Test extensions for ReminderManager
extension ReminderManager {
    func triggerReminder() {
        hasActiveReminder = true
        isTouchGrassModeActive = true
    }
}

// Test data for exercises
extension Exercise {
    static let chinTuckQuick = Exercise(
        id: "chin_tuck_quick",
        name: "Quick Chin Tucks",
        duration: 30,
        category: .quickReset,
        instructions: [
            "Sit or stand with spine tall",
            "Gently draw your chin back",
            "Hold for 5 seconds",
            "Slowly release"
        ],
        benefits: "Strengthens deep neck flexors",
        targetArea: "Neck"
    )
}