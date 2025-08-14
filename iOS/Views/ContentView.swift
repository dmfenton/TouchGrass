import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: iOSReminderManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(manager: manager)
                .tabItem {
                    Label("Home", systemImage: "leaf.circle.fill")
                }
                .tag(0)
            
            ExercisesView(manager: manager)
                .tabItem {
                    Label("Exercises", systemImage: "figure.flexibility")
                }
                .tag(1)
            
            WaterView(manager: manager)
                .tabItem {
                    Label("Water", systemImage: "drop.fill")
                }
                .tag(2)
            
            StatsView(manager: manager)
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            SettingsView(manager: manager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

// Home View
struct HomeView: View {
    @ObservedObject var manager: iOSReminderManager
    
    var nextReminderText: String {
        let totalSeconds = Int(manager.timeUntilNextReminder)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if totalSeconds <= 0 {
            return "Any moment..."
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer Card
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(manager.isPaused ? "Paused" : nextReminderText)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(manager.isPaused ? .orange : .primary)
                        
                        Text(manager.isPaused ? "Reminders paused" : "until next reminder")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                if manager.isPaused {
                                    manager.resume()
                                } else {
                                    manager.pause()
                                }
                            }) {
                                Image(systemName: manager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(manager.isPaused ? .green : .orange)
                            }
                            
                            if !manager.isPaused {
                                Button(action: {
                                    manager.snoozeReminder()
                                }) {
                                    VStack {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 30))
                                        Text("Snooze 5m")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    )
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionCard(
                                    icon: "leaf.fill",
                                    title: "Touch Grass",
                                    subtitle: "Go outside now",
                                    color: .green
                                ) {
                                    manager.completeActivity("Touch Grass")
                                    manager.completeBreak()
                                }
                                
                                QuickActionCard(
                                    icon: "figure.walk",
                                    title: "Quick Walk",
                                    subtitle: "5 min stroll",
                                    color: .blue
                                ) {
                                    manager.completeActivity("Quick Walk")
                                    manager.completeBreak()
                                }
                                
                                QuickActionCard(
                                    icon: "figure.flexibility",
                                    title: "Stretch",
                                    subtitle: "2 min routine",
                                    color: .purple
                                ) {
                                    // Navigate to exercises
                                }
                                
                                QuickActionCard(
                                    icon: "drop.fill",
                                    title: "Log Water",
                                    subtitle: "+1 glass",
                                    color: .blue
                                ) {
                                    manager.logWater(1)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Today's Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Progress")
                            .font(.headline)
                        
                        ProgressRow(
                            icon: "flame.fill",
                            title: "Streak",
                            value: "\(manager.currentStreak) days",
                            color: .orange
                        )
                        
                        ProgressRow(
                            icon: "drop.fill",
                            title: "Water",
                            value: "\(manager.currentWaterIntake)/\(manager.dailyWaterGoal) glasses",
                            color: .blue
                        )
                        
                        ProgressRow(
                            icon: "checkmark.circle.fill",
                            title: "Activities",
                            value: "\(manager.completedActivities.count) completed",
                            color: .green
                        )
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
            .navigationTitle("Touch Grass")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5)
            )
        }
    }
}

// Progress Row
struct ProgressRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}