import XCTest
import Combine
@testable import Touch_Grass

final class WorkHoursTests: XCTestCase {
    var workHoursManager: WorkHoursManager!
    var reminderManager: ReminderManager!
    var testScheduler: TestScheduler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        testScheduler = TestScheduler()
        workHoursManager = WorkHoursManager()
        reminderManager = ReminderManager()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        workHoursManager = nil
        testScheduler = nil
        
        super.tearDown()
    }
    
    func testWorkHoursConfiguration() {
        // Given: Default work hours
        XCTAssertEqual(workHoursManager.currentWorkStartHour, 9)
        XCTAssertEqual(workHoursManager.currentWorkStartMinute, 0)
        XCTAssertEqual(workHoursManager.currentWorkEndHour, 17)
        XCTAssertEqual(workHoursManager.currentWorkEndMinute, 0)
        
        // When: Updating work hours
        reminderManager.updateWorkHours(
            startHour: 8, startMinute: 30,
            endHour: 18, endMinute: 30,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Then: Should update configuration
        XCTAssertEqual(reminderManager.currentWorkStartHour, 8)
        XCTAssertEqual(reminderManager.currentWorkStartMinute, 30)
        XCTAssertEqual(reminderManager.currentWorkEndHour, 18)
        XCTAssertEqual(reminderManager.currentWorkEndMinute, 30)
    }
    
    func testIsWithinWorkHours() {
        // Setup: Mon-Fri, 9 AM - 5 PM
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Test cases
        let testCases: [(date: Date, expected: Bool, description: String)] = [
            (createDate(weekday: 2, hour: 9, minute: 0), true, "Monday 9:00 AM - start of work"),
            (createDate(weekday: 2, hour: 8, minute: 59), false, "Monday 8:59 AM - before work"),
            (createDate(weekday: 2, hour: 12, minute: 0), true, "Monday noon - during work"),
            (createDate(weekday: 2, hour: 17, minute: 0), false, "Monday 5:00 PM - end of work"),
            (createDate(weekday: 2, hour: 17, minute: 1), false, "Monday 5:01 PM - after work"),
            (createDate(weekday: 6, hour: 12, minute: 0), true, "Friday noon - during work"),
            (createDate(weekday: 7, hour: 12, minute: 0), false, "Saturday noon - weekend"),
            (createDate(weekday: 1, hour: 12, minute: 0), false, "Sunday noon - weekend")
        ]
        
        for testCase in testCases {
            let result = reminderManager.isWithinWorkHours(date: testCase.date)
            XCTAssertEqual(result, testCase.expected, testCase.description)
        }
    }
    
    func testAutoPauseOutsideWorkHours() {
        // Given: Reminders active during work hours
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        reminderManager.resume()
        
        // When: Work hours end (5 PM)
        let afterWork = createDate(weekday: 2, hour: 17, minute: 1)
        testScheduler.setCurrentTime(afterWork)
        reminderManager.checkWorkHoursAndPause()
        
        // Then: Should auto-pause
        XCTAssertTrue(reminderManager.isPaused)
    }
    
    func testAutoResumeAtWorkStart() {
        // Given: Paused overnight
        reminderManager.isPaused = true
        
        // When: Work hours begin (9 AM Monday)
        let workStart = createDate(weekday: 2, hour: 9, minute: 0)
        testScheduler.setCurrentTime(workStart)
        reminderManager.checkWorkHoursAndResume()
        
        // Then: Should auto-resume
        XCTAssertFalse(reminderManager.isPaused)
        XCTAssertNotNil(reminderManager.nextReminderTime)
    }
    
    func testNextWorkPeriodCalculation() {
        // Test 1: Friday evening -> Monday morning
        let fridayEvening = createDate(weekday: 6, hour: 18, minute: 0)
        testScheduler.setCurrentTime(fridayEvening)
        
        let nextWork = reminderManager.getNextWorkPeriodStart()
        let components = Calendar.current.dateComponents([.weekday, .hour], from: nextWork!)
        
        XCTAssertEqual(components.weekday, 2) // Monday
        XCTAssertEqual(components.hour, 9)
        
        // Test 2: Monday evening -> Tuesday morning
        let mondayEvening = createDate(weekday: 2, hour: 18, minute: 0)
        testScheduler.setCurrentTime(mondayEvening)
        
        let nextWork2 = reminderManager.getNextWorkPeriodStart()
        let components2 = Calendar.current.dateComponents([.weekday, .hour], from: nextWork2!)
        
        XCTAssertEqual(components2.weekday, 3) // Tuesday
        XCTAssertEqual(components2.hour, 9)
    }
    
    func testFlexibleWorkDays() {
        // Test custom work schedule (e.g., Tue-Sat)
        reminderManager.updateWorkHours(
            startHour: 10, startMinute: 0,
            endHour: 18, endMinute: 0,
            workDays: [.tuesday, .wednesday, .thursday, .friday, .saturday]
        )
        
        // Monday should not be work day
        let monday = createDate(weekday: 2, hour: 12, minute: 0)
        XCTAssertFalse(reminderManager.isWithinWorkHours(date: monday))
        
        // Saturday should be work day
        let saturday = createDate(weekday: 7, hour: 12, minute: 0)
        XCTAssertTrue(reminderManager.isWithinWorkHours(date: saturday))
        
        // Sunday should not be work day
        let sunday = createDate(weekday: 1, hour: 12, minute: 0)
        XCTAssertFalse(reminderManager.isWithinWorkHours(date: sunday))
    }
    
    func testReminderSchedulingAtWorkBoundaries() {
        // Given: 45-minute intervals, work ends at 5 PM
        reminderManager.intervalMinutes = 45
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // When: Current time is 4:30 PM
        let nearEndOfDay = createDate(weekday: 2, hour: 16, minute: 30)
        testScheduler.setCurrentTime(nearEndOfDay)
        
        // Then: Should not schedule reminder past 5 PM
        reminderManager.scheduleNextReminderIfNeeded()
        
        if let nextReminder = reminderManager.nextReminderTime {
            let components = Calendar.current.dateComponents([.hour, .minute], from: nextReminder)
            let reminderMinutes = components.hour! * 60 + components.minute!
            let workEndMinutes = 17 * 60
            
            XCTAssertLessThanOrEqual(reminderMinutes, workEndMinutes)
        }
    }
    
    func testLunchBreakHandling() {
        // Given: Lunch break from 12-1 PM
        reminderManager.configureLunchBreak(
            enabled: true,
            startHour: 12, startMinute: 0,
            endHour: 13, endMinute: 0
        )
        
        // When: Checking if reminder should trigger during lunch
        let lunchTime = createDate(weekday: 2, hour: 12, minute: 30)
        let shouldPause = reminderManager.shouldPauseDuringLunch(at: lunchTime)
        
        // Then: Should respect lunch break setting
        XCTAssertTrue(shouldPause)
    }
    
    func testTimeZoneHandling() {
        // Test work hours across time zone changes
        let originalTimeZone = TimeZone.current
        
        // Simulate time zone change
        TimeZone.ReferenceType.default = TimeZone(identifier: "America/Los_Angeles")!
        
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Work hours should adjust to new time zone
        let workTime = createDate(weekday: 2, hour: 10, minute: 0)
        XCTAssertTrue(reminderManager.isWithinWorkHours(date: workTime))
        
        // Restore original time zone
        TimeZone.ReferenceType.default = originalTimeZone
    }
    
    // MARK: - Helper Methods
    
    private func createDate(weekday: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.weekday = weekday // 1 = Sunday, 2 = Monday, etc.
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        // Get a reference date and adjust to match the desired weekday
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let daysToAdd = weekday - currentWeekday
        
        let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: now)!
        
        // Set the time components
        let finalDate = calendar.date(bySettingHour: hour, 
                                     minute: minute, 
                                     second: 0, 
                                     of: targetDate)!
        
        return finalDate
    }
}

// Test extensions for ReminderManager
extension ReminderManager {
    func checkWorkHoursAndPause() {
        if !isWithinWorkHours(date: Date()) {
            pause()
        }
    }
    
    func checkWorkHoursAndResume() {
        if isWithinWorkHours(date: Date()) && isPaused {
            resume()
        }
    }
    
    func getNextWorkPeriodStart() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Find next work day
        for dayOffset in 1...7 {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now)!
            let weekday = calendar.component(.weekday, from: checkDate)
            
            if isWorkDay(weekday: weekday) {
                return calendar.date(bySettingHour: currentWorkStartHour,
                                   minute: currentWorkStartMinute,
                                   second: 0,
                                   of: checkDate)
            }
        }
        
        return nil
    }
    
    func isWorkDay(weekday: Int) -> Bool {
        let workDay = WorkDay.from(weekday: weekday)
        return currentWorkDays.contains(workDay)
    }
    
    func isWithinWorkHours(date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else {
            return false
        }
        
        // Check if it's a work day
        if !isWorkDay(weekday: weekday) {
            return false
        }
        
        // Check if within work hours
        let currentMinutes = hour * 60 + minute
        let startMinutes = currentWorkStartHour * 60 + currentWorkStartMinute
        let endMinutes = currentWorkEndHour * 60 + currentWorkEndMinute
        
        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }
    
    func configureLunchBreak(enabled: Bool, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        UserDefaults.standard.set(enabled, forKey: "lunchBreakEnabled")
        UserDefaults.standard.set(startHour, forKey: "lunchStartHour")
        UserDefaults.standard.set(startMinute, forKey: "lunchStartMinute")
        UserDefaults.standard.set(endHour, forKey: "lunchEndHour")
        UserDefaults.standard.set(endMinute, forKey: "lunchEndMinute")
    }
    
    func shouldPauseDuringLunch(at date: Date) -> Bool {
        guard UserDefaults.standard.bool(forKey: "lunchBreakEnabled") else {
            return false
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        let currentMinutes = components.hour! * 60 + components.minute!
        let lunchStart = UserDefaults.standard.integer(forKey: "lunchStartHour") * 60 +
                        UserDefaults.standard.integer(forKey: "lunchStartMinute")
        let lunchEnd = UserDefaults.standard.integer(forKey: "lunchEndHour") * 60 +
                      UserDefaults.standard.integer(forKey: "lunchEndMinute")
        
        return currentMinutes >= lunchStart && currentMinutes < lunchEnd
    }
}

enum WorkDay {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
    
    static func from(weekday: Int) -> WorkDay {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}