import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var manager: iOSReminderManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Streak Overview
                    VStack(spacing: 16) {
                        Text("Streak Overview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 20) {
                            StreakCard(
                                title: "Current",
                                value: manager.currentStreak,
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StreakCard(
                                title: "Best",
                                value: manager.bestStreak,
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Today's Activities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Activities")
                            .font(.headline)
                        
                        if manager.completedActivities.isEmpty {
                            Text("No activities completed yet today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 30)
                        } else {
                            ForEach(manager.completedActivities, id: \.self) { activity in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(activity)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // Weekly Overview (placeholder for future implementation)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weekly Activity")
                            .font(.headline)
                        
                        // Simple bar chart representation
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<7) { day in
                                VStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(day == 6 ? Color.green : Color.green.opacity(0.3))
                                        .frame(width: 40, height: CGFloat.random(in: 20...100))
                                    
                                    Text(weekdayLabel(for: day))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(height: 120)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Achievements")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            AchievementBadge(
                                icon: "star.fill",
                                title: "First Step",
                                subtitle: "Complete your first break",
                                isUnlocked: !manager.completedActivities.isEmpty
                            )
                            
                            AchievementBadge(
                                icon: "flame.fill",
                                title: "On Fire",
                                subtitle: "7 day streak",
                                isUnlocked: manager.bestStreak >= 7
                            )
                            
                            AchievementBadge(
                                icon: "drop.fill",
                                title: "Hydrated",
                                subtitle: "Meet water goal",
                                isUnlocked: manager.currentWaterIntake >= manager.dailyWaterGoal
                            )
                            
                            AchievementBadge(
                                icon: "trophy.fill",
                                title: "Champion",
                                subtitle: "30 day streak",
                                isUnlocked: manager.bestStreak >= 30
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    func weekdayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
}

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(isUnlocked ? .yellow : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 2)
                )
        )
        .opacity(isUnlocked ? 1 : 0.5)
    }
}