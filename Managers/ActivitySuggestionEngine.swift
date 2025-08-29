import Foundation
import SwiftUI

// MARK: - Activity Suggestion Data Types

// New: Separate hydration from activity suggestions
struct ActivityRecommendations {
    let hydrationReminder: HydrationReminder?
    let activitySuggestion: SuggestedActivity
}

struct HydrationReminder {
    let shouldRemind: Bool
    let message: String
    let urgency: Double  // 0-1 score
    let glassesNeeded: Int
    let currentIntake: Int
    let dailyGoal: Int
}

enum ActivityCategory: String, CaseIterable {
    case outdoor
    case physical
    case mental
    case posture
    // Removed hydration - now handled separately
}

enum TimeWindow: String {
    case micro           // <2 min
    case quick           // 2-5 min
    case standard        // 5-10 min
    case extended        // 10-15 min
    case long            // >15 min
    
    static func from(minutes: Int) -> TimeWindow {
        switch minutes {
        case ..<2: return .micro
        case 2..<5: return .quick
        case 5..<10: return .standard
        case 10..<15: return .extended
        default: return .long
        }
    }
    
    var maxDuration: Int {
        switch self {
        case .micro: return 2
        case .quick: return 5
        case .standard: return 10
        case .extended: return 15
        case .long: return 30
        }
    }
}

struct SuggestedActivity {
    let type: String  // "touchGrass", "exercise", "meditation", "breathing"
    let title: String
    let reason: String
    let duration: Int  // minutes
    let category: ActivityCategory
    let urgency: Double  // 0-1 score
    let exerciseSet: ExerciseSet?  // If it's an exercise
    
    init(type: String, title: String, reason: String, duration: Int, category: ActivityCategory, urgency: Double = 0.5, exerciseSet: ExerciseSet? = nil) {
        self.type = type
        self.title = title
        self.reason = reason
        self.duration = duration
        self.category = category
        self.urgency = urgency
        self.exerciseSet = exerciseSet
    }
}

// MARK: - Context Data

struct ActivityContext {
    let currentTime: Date
    let availableMinutes: Int
    let weather: WeatherInfo?
    let timeSinceLastBreak: TimeInterval
    let todaysActivities: [CompletedActivity]
    let meetingDensity: MeetingDensity
    let nextMeeting: Date?
    let currentStreak: Int
    let waterIntake: Int  // glasses
    let dailyWaterGoal: Int
    
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 6..<9: return .earlyMorning
        case 9..<12: return .midMorning
        case 12..<13: return .lunch
        case 13..<15: return .earlyAfternoon
        case 15..<17: return .lateAfternoon
        default: return .evening
        }
    }
    
    var timeWindow: TimeWindow {
        return TimeWindow.from(minutes: availableMinutes)
    }
    
    var hasBeenSittingLong: Bool {
        return timeSinceLastBreak > 5400  // 90 minutes
    }
    
    // needsHydration removed - now handled in HydrationReminder
}

enum TimeOfDay {
    case earlyMorning
    case midMorning  
    case lunch
    case earlyAfternoon
    case lateAfternoon
    case evening
}

enum MeetingDensity {
    case light    // <3 meetings
    case normal   // 3-5 meetings
    case heavy    // >5 meetings
}

struct CompletedActivity {
    let type: String
    let category: ActivityCategory
    let completedAt: Date
    let duration: Int
}

// MARK: - Main Suggestion Engine

class ActivitySuggestionEngine: ObservableObject {
    @Published var currentSuggestion: SuggestedActivity?
    
    private let reminderManager: ReminderManager
    private let weatherService: WeatherServiceProtocol
    
    // Simple file logging for debugging
    private func logToFile(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        let logURL = URL(fileURLWithPath: "/tmp/touchgrass_debug.log")
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }
    
    // Public getter for weather service
    var weather: WeatherServiceProtocol { weatherService }
    
    // Method to refresh weather cache
    func refreshWeatherCache() {
        Task {
            _ = await weatherService.getCurrentWeather()
        }
    }
    
    init(reminderManager: ReminderManager) {
        self.reminderManager = reminderManager
        self.weatherService = WeatherServiceFactory.create()
        
        // Pre-cache weather data on initialization
        Task {
            _ = await weatherService.getCurrentWeather()
        }
    }
    
    // MARK: - Public Interface
    
    // New: Get both hydration and activity recommendations
    func getRecommendations() async -> ActivityRecommendations {
        let context = await buildContext()
        return ActivityRecommendations(
            hydrationReminder: buildHydrationReminder(for: context),
            activitySuggestion: calculateBestActivity(for: context)
        )
    }
    
    func getRecommendationsSync() -> ActivityRecommendations {
        let context = buildContextSync()
        return ActivityRecommendations(
            hydrationReminder: buildHydrationReminder(for: context),
            activitySuggestion: calculateBestActivity(for: context)
        )
    }
    
    // Legacy methods for backward compatibility
    func getSuggestion() async -> SuggestedActivity {
        let recommendations = await getRecommendations()
        return recommendations.activitySuggestion
    }
    
    func getSuggestionSync() -> SuggestedActivity {
        let recommendations = getRecommendationsSync()
        return recommendations.activitySuggestion
    }
    
    // MARK: - Context Building
    
    private func buildContext() async -> ActivityContext {
        let weather = await weatherService.getCurrentWeather()
        return buildContextBase(weather: weather)
    }
    
    private func buildContextSync() -> ActivityContext {
        let weather = weatherService.getCurrentWeatherSync()
        return buildContextBase(weather: weather)
    }
    
    private func buildContextBase(weather: WeatherInfo?) -> ActivityContext {
        let now = Date()
        _ = Calendar.current
        
        // Calculate available time
        var availableMinutes = Int(reminderManager.intervalMinutes)
        
        if let calManager = reminderManager.calendarManager {
            logToFile("🔍 [Calendar] Calendar manager exists")
            logToFile("🔍 [Calendar] Has calendar access: \(calManager.hasCalendarAccess)")
            logToFile("🔍 [Calendar] Is in meeting: \(calManager.isInMeeting)")
            logToFile("🔍 [Calendar] Current event: \(calManager.currentEvent?.title ?? "none")")
            logToFile("🔍 [Calendar] Next event: \(calManager.nextEvent?.title ?? "none")")
            
            // If currently in a meeting, suggest very short activities only
            if calManager.isInMeeting {
                availableMinutes = 2  // Max 2 minutes during meetings
                logToFile("🔍 [Calendar] In meeting - limiting to 2 minutes")
            } else if let nextEvent = calManager.nextEvent {
                let timeUntilEvent = nextEvent.startDate.timeIntervalSince(now) / 60
                availableMinutes = min(availableMinutes, Int(timeUntilEvent))
                logToFile("🔍 [Calendar] Next meeting in \(Int(timeUntilEvent)) minutes")
            }
        } else {
            logToFile("🔍 [Calendar] No calendar manager - using conservative 5 minute limit")
            availableMinutes = min(availableMinutes, 5)  // Conservative default when no calendar
        }
        availableMinutes = max(1, availableMinutes)  // At least 1 minute
        logToFile("🔍 [Calendar] Final available minutes: \(availableMinutes)")
        
        // Get today's activities from activity tracker
        let todaysActivities = getTodaysActivities()
        
        // Calculate meeting density (simplified for now)
        let meetingCount = 3  // TODO: (#100) Get actual meeting count from calendar
        let density: MeetingDensity = meetingCount < 3 ? .light : (meetingCount <= 5 ? .normal : .heavy)
        
        // Time since last break (calculate from activity tracker)
        let timeSinceLastBreak: TimeInterval = 5400  // Default to 90 minutes
        
        return ActivityContext(
            currentTime: now,
            availableMinutes: availableMinutes,
            weather: weather,
            timeSinceLastBreak: timeSinceLastBreak,
            todaysActivities: todaysActivities,
            meetingDensity: density,
            nextMeeting: reminderManager.calendarManager?.nextEvent?.startDate,
            currentStreak: reminderManager.currentStreak,
            waterIntake: reminderManager.currentWaterIntake,
            dailyWaterGoal: reminderManager.dailyWaterGoal
        )
    }
    
    private func getTodaysActivities() -> [CompletedActivity] {
        // Simplified for now - will integrate with ActivityTracker properly later
        return []
    }
    
    // MARK: - Hydration Decision Logic
    
    private func buildHydrationReminder(for context: ActivityContext) -> HydrationReminder? {
        let intake = context.waterIntake
        let goal = context.dailyWaterGoal
        
        // Don't remind if already met goal
        guard intake < goal else { return nil }
        
        let percentage = Double(intake) / Double(goal)
        let glassesNeeded = goal - intake
        
        // Determine urgency and message based on progress
        let (shouldRemind, message, urgency) = if percentage < 0.25 {
            // Less than 25% of goal
            (true, "Hydration low - you're at \(intake)/\(goal) glasses today", 0.9)
        } else if percentage < 0.5 {
            // Less than 50% of goal
            (true, "Drink water - you're at \(intake)/\(goal) glasses today", 0.7)
        } else if percentage < 0.75 {
            // Less than 75% of goal
            (true, "Keep hydrating - \(glassesNeeded) more glasses to go", 0.5)
        } else {
            // 75%+ of goal - gentle reminder only
            (true, "Almost there - just \(glassesNeeded) more glass\(glassesNeeded == 1 ? "" : "es")", 0.3)
        }
        
        return HydrationReminder(
            shouldRemind: shouldRemind,
            message: message,
            urgency: urgency,
            glassesNeeded: glassesNeeded,
            currentIntake: intake,
            dailyGoal: goal
        )
    }
    
    // MARK: - Decision Tree Implementation
    
    func calculateBestActivity(for context: ActivityContext) -> SuggestedActivity {
        // Debug logging for context
        logToFile("🔍 [Recommendation] === CALCULATING BEST ACTIVITY ===")
        logToFile("🔍 [Recommendation] Available minutes: \(context.availableMinutes)")
        logToFile("🔍 [Recommendation] Time window: \(context.timeWindow)")
        logToFile("🔍 [Recommendation] Weather: \(context.weather?.temperature ?? -999)°F, \(context.weather?.condition.rawValue ?? "none")")
        logToFile("🔍 [Recommendation] Weather ideal for outdoor: \(context.weather?.isIdealForOutdoor ?? false)")
        logToFile("🔍 [Recommendation] Next meeting: \(context.nextMeeting?.description ?? "none")")
        logToFile("🔍 [Recommendation] Has been sitting long: \(context.hasBeenSittingLong)")
        
        // 1. Time Constraint Filter - ALWAYS FIRST
        let availableActivities = filterByTimeConstraint(context: context)
        logToFile("🔍 [Recommendation] Available activities after time filter: \(availableActivities.map { $0.title }.joined(separator: ", "))")
        
        // 2. Critical Time Windows
        if let critical = checkCriticalTimeWindows(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Critical Time Window - \(critical.title)")
            return critical
        }
        logToFile("🔍 [Recommendation] No critical time windows detected")
        
        // 3. Weather Window of Opportunity
        if let weatherOptimal = checkWeatherOpportunity(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Weather Opportunity - \(weatherOptimal.title)")
            return weatherOptimal
        }
        logToFile("🔍 [Recommendation] No weather opportunities")
        
        // 4. Critical Physical Needs
        if let physical = checkPhysicalNeeds(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Physical Needs - \(physical.title)")
            return physical
        }
        logToFile("🔍 [Recommendation] No critical physical needs")
        
        // 5. Day Schedule Awareness
        if let scheduled = checkDaySchedule(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Day Schedule - \(scheduled.title)")
            return scheduled
        }
        logToFile("🔍 [Recommendation] No day schedule priorities")
        
        // 6. Time-of-Day Optimization
        if let timeOptimal = checkTimeOfDay(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Time of Day - \(timeOptimal.title)")
            return timeOptimal
        }
        logToFile("🔍 [Recommendation] No time-of-day optimizations")
        
        // 7. Variety & Balance
        if let balanced = checkVarietyBalance(context: context, activities: availableActivities) {
            logToFile("🔍 [Recommendation] SELECTED: Variety Balance - \(balanced.title)")
            return balanced
        }
        logToFile("🔍 [Recommendation] No variety balance needed")
        
        // 8. Smart Default
        let defaultActivity = getSmartDefault(context: context, activities: availableActivities)
        logToFile("🔍 [Recommendation] SELECTED: Smart Default - \(defaultActivity.title)")
        return defaultActivity
    }
    
    // MARK: - Decision Filters
    
    private func filterByTimeConstraint(context: ActivityContext) -> [SuggestedActivity] {
        var activities: [SuggestedActivity] = []
        
        switch context.timeWindow {
        case .micro:
            // Only micro activities
            activities.append(SuggestedActivity(
                type: "breathing",
                title: "Quick Breathing",
                reason: "Perfect for a quick reset",
                duration: 1,
                category: .mental
            ))
            activities.append(SuggestedActivity(
                type: "exercise",
                title: "Eye Rest",
                reason: "Give your eyes a break",
                duration: 1,
                category: .physical,
                exerciseSet: nil  // TODO: (#101) Add eye rest exercise
            ))
            
        case .quick:
            // Quick activities (hydration removed - now handled separately)
            activities.append(SuggestedActivity(
                type: "exercise",
                title: "Desk Stretches",
                reason: "Quick posture reset",
                duration: 3,
                category: .posture,
                exerciseSet: nil  // TODO: (#102) Add desk stretch set
            ))
            activities.append(SuggestedActivity(
                type: "breathing",
                title: "Deep Breathing",
                reason: "Quick mental reset",
                duration: 2,
                category: .mental
            ))
            
        case .standard:
            // Standard activities
            activities.append(SuggestedActivity(
                type: "touchGrass",
                title: "Touch Grass",
                reason: "Get some fresh air",
                duration: 7,
                category: .outdoor
            ))
            activities.append(SuggestedActivity(
                type: "exercise",
                title: "Posture Routine",
                reason: "Full posture reset",
                duration: 5,
                category: .physical,
                exerciseSet: ExerciseData.upperBodyRoutine
            ))
            
        case .extended, .long:
            // All activities available
            activities.append(SuggestedActivity(
                type: "touchGrass",
                title: "Extended Outdoor Time",
                reason: "Perfect time for a real break",
                duration: 10,
                category: .outdoor
            ))
            activities.append(SuggestedActivity(
                type: "exercise",
                title: "Back & Core Routine",
                reason: "Comprehensive movement break",
                duration: 4,
                category: .physical,
                exerciseSet: ExerciseData.backCoreRoutine
            ))
            activities.append(SuggestedActivity(
                type: "meditation",
                title: "Meditation",
                reason: "Mental reset and focus",
                duration: 10,
                category: .mental
            ))
        }
        
        return activities
    }
    
    private func checkCriticalTimeWindows(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        // About to have a meeting - quick energizer
        if let nextMeeting = context.nextMeeting {
            let timeUntil = nextMeeting.timeIntervalSince(context.currentTime) / 60
            if timeUntil >= 3 && timeUntil <= 7 && context.timeSinceLastBreak > 5400 {
                if let exercise = activities.first(where: { $0.category == .physical && $0.duration <= 3 }) {
                    // var modified = exercise  // Not used currently
                    return SuggestedActivity(
                        type: exercise.type,
                        title: exercise.title,
                        reason: "Quick energy boost before your meeting",
                        duration: exercise.duration,
                        category: exercise.category,
                        urgency: 0.8,
                        exerciseSet: exercise.exerciseSet
                    )
                }
            }
        }
        
        // Just finished long meeting block
        if context.timeSinceLastBreak > 7200 {  // 2+ hours
            if context.availableMinutes >= 10 {
                if let outdoor = activities.first(where: { $0.type == "touchGrass" }) {
                    return SuggestedActivity(
                        type: outdoor.type,
                        title: "Recovery Walk",
                        reason: "You've been sitting for 2+ hours - time to move!",
                        duration: outdoor.duration,
                        category: outdoor.category,
                        urgency: 0.9
                    )
                }
            }
        }
        
        return nil
    }
    
    private func checkWeatherOpportunity(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        guard let weather = context.weather,
              weather.isIdealForOutdoor,
              context.availableMinutes >= 5 else { return nil }
        
        // Check if we've done outdoor today
        let hasOutdoorToday = context.todaysActivities.contains { $0.category == .outdoor }
        
        if !hasOutdoorToday {
            return SuggestedActivity(
                type: "touchGrass",
                title: "Perfect Weather Outside!",
                reason: "It's \(Int(weather.temperature))°F and \(weather.description) - don't miss this!",
                duration: min(10, context.availableMinutes),
                category: .outdoor,
                urgency: 0.85
            )
        }
        
        return nil
    }
    
    private func checkPhysicalNeeds(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        // Sitting too long
        if context.hasBeenSittingLong {
            // Prioritize movement
            if let movement = activities.first(where: { $0.category == .physical || $0.category == .outdoor }) {
                return SuggestedActivity(
                    type: movement.type,
                    title: movement.title,
                    reason: "You've been sitting for \(Int(context.timeSinceLastBreak / 60)) minutes",
                    duration: movement.duration,
                    category: movement.category,
                    urgency: 0.75,
                    exerciseSet: movement.exerciseSet
                )
            }
        }
        
        // Hydration is now handled separately in HydrationReminder
        
        return nil
    }
    
    private func checkDaySchedule(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        // Heavy meeting day - prioritize high-impact breaks
        if context.meetingDensity == .heavy {
            let substantialBreaks = context.todaysActivities.filter { $0.duration >= 5 }.count
            
            if substantialBreaks < 2 {
                // Need more substantial breaks
                if let substantial = activities.first(where: { $0.duration >= 5 }) {
                    return SuggestedActivity(
                        type: substantial.type,
                        title: substantial.title,
                        reason: "Heavy meeting day - make this break count!",
                        duration: substantial.duration,
                        category: substantial.category,
                        urgency: 0.8,
                        exerciseSet: substantial.exerciseSet
                    )
                }
            }
        }
        
        // End of day approaching - last chance for outdoor
        let hour = Calendar.current.component(.hour, from: context.currentTime)
        if hour >= 16 && hour < 18 {
            let hasOutdoor = context.todaysActivities.contains { $0.category == .outdoor }
            if !hasOutdoor && context.weather?.isGoodForOutdoor == true {
                return SuggestedActivity(
                    type: "touchGrass",
                    title: "Last Chance for Fresh Air",
                    reason: "Day is ending - get outside while you can!",
                    duration: min(10, context.availableMinutes),
                    category: .outdoor,
                    urgency: 0.75
                )
            }
        }
        
        return nil
    }
    
    private func checkTimeOfDay(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        switch context.timeOfDay {
        case .earlyAfternoon:
            // Post-lunch slump - energizing activity
            if let energizer = activities.first(where: { $0.category == .physical || $0.type == "touchGrass" }) {
                return SuggestedActivity(
                    type: energizer.type,
                    title: energizer.title,
                    reason: "Beat the afternoon slump",
                    duration: energizer.duration,
                    category: energizer.category,
                    urgency: 0.7,
                    exerciseSet: energizer.exerciseSet
                )
            }
            
        case .lateAfternoon:
            // Wind down if heavy day
            if context.meetingDensity == .heavy {
                if let calming = activities.first(where: { $0.category == .mental }) {
                    return SuggestedActivity(
                        type: calming.type,
                        title: calming.title,
                        reason: "Time to decompress after a busy day",
                        duration: calming.duration,
                        category: calming.category,
                        urgency: 0.65
                    )
                }
            }
            
        case .midMorning:
            // Prime time for outdoor if weather is good
            if context.weather?.isIdealForOutdoor == true {
                if let outdoor = activities.first(where: { $0.type == "touchGrass" }) {
                    return SuggestedActivity(
                        type: outdoor.type,
                        title: outdoor.title,
                        reason: "Beautiful morning - start your day right!",
                        duration: outdoor.duration,
                        category: outdoor.category,
                        urgency: 0.7
                    )
                }
            }
            
        default:
            break
        }
        
        return nil
    }
    
    private func checkVarietyBalance(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity? {
        // Get category counts for today
        var categoryCounts: [ActivityCategory: Int] = [:]
        for activity in context.todaysActivities {
            categoryCounts[activity.category, default: 0] += 1
        }
        
        // Find least done category
        let allCategories: [ActivityCategory] = [.outdoor, .physical, .mental, .posture]
        let leastDone = allCategories.min { 
            categoryCounts[$0, default: 0] < categoryCounts[$1, default: 0]
        }
        
        if let targetCategory = leastDone {
            if let activity = activities.first(where: { $0.category == targetCategory }) {
                let count = categoryCounts[targetCategory, default: 0]
                let reason = categoryCounts[targetCategory, default: 0] == 0 ? 
                    "You haven't done any \(targetCategory.rawValue) activities today" :
                    "Balance your day with more \(targetCategory.rawValue) activities"
                
                return SuggestedActivity(
                    type: activity.type,
                    title: activity.title,
                    reason: reason,
                    duration: activity.duration,
                    category: activity.category,
                    urgency: 0.6,
                    exerciseSet: activity.exerciseSet
                )
            }
        }
        
        return nil
    }
    
    private func getSmartDefault(context: ActivityContext, activities: [SuggestedActivity]) -> SuggestedActivity {
        // Smart defaults based on available time
        if context.availableMinutes < 3 {
            return SuggestedActivity(
                type: "breathing",
                title: "Quick Reset",
                reason: "Take a moment to breathe",
                duration: 1,
                category: .mental,
                urgency: 0.5
            )
        }
        
        if context.hasBeenSittingLong {
            if let movement = activities.first(where: { $0.category == .physical }) {
                return SuggestedActivity(
                    type: movement.type,
                    title: movement.title,
                    reason: "Time to move",
                    duration: movement.duration,
                    category: movement.category,
                    urgency: 0.5,
                    exerciseSet: movement.exerciseSet
                )
            }
        }
        
        // Final fallback
        return activities.first ?? SuggestedActivity(
            type: "touchGrass",
            title: "Take a Break",
            reason: "Step away from your desk",
            duration: 5,
            category: .outdoor,
            urgency: 0.5
        )
    }
}
