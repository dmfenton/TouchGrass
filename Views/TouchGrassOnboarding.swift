import SwiftUI
import UserNotifications
import EventKit

struct TouchGrassOnboarding: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var customizationWindow: CustomizationWindowController?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeaderView()
            
            // Main message
            Text("Sitting all day is rough. We'll remind you to move, stretch, hydrate, and literally go touch some grass.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            // Features list with nature theme
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "figure.walk",
                    title: "Regular movement breaks",
                    subtitle: "Stand up every 45 minutes"
                )
                
                FeatureRow(
                    icon: "clock.badge.checkmark",
                    title: "Work hours aware",
                    subtitle: "Active only 9am - 5pm weekdays"
                )
                
                FeatureRow(
                    icon: "drop.fill",
                    title: "Stay hydrated",
                    subtitle: "Track water intake goals"
                )
                
                FeatureRow(
                    icon: "leaf.fill",
                    title: "Build healthy habits",
                    subtitle: "Track your daily streak"
                )
                
                FeatureRow(
                    icon: "calendar",
                    title: "Meeting smart",
                    subtitle: "Pauses during your calls"
                )
                
                FeatureRow(
                    icon: "wand.and.stars",
                    title: "Adaptive timing",
                    subtitle: "Learns your work patterns"
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Bottom section with two clear CTAs
            VStack(spacing: 16) {
                Text("🌱 Ready to feel better at work?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Button(action: openCustomization) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13))
                            Text("Customize")
                        }
                        .frame(width: 120)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 1.5)
                        )
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: quickStart) {
                        HStack(spacing: 6) {
                            Text("Let's Go")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(width: 140)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(30)
        }
        .frame(width: 520, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func openCustomization() {
        // Close the onboarding window first
        dismiss()
        
        // Then open customization
        customizationWindow = CustomizationWindowController(
            reminderManager: reminderManager,
            onComplete: {
                // Mark onboarding as complete after customization
                UserDefaults.standard.set(true, forKey: "TouchGrass.hasCompletedOnboarding")
                
                // Request notifications if needed (note: can't capture self as it's a struct)
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        )
        customizationWindow?.showCustomization()
    }
    
    private func quickStart() {
        // Use default settings
        reminderManager.intervalMinutes = 45
        reminderManager.adaptiveIntervalEnabled = true
        reminderManager.startsAtLogin = false
        reminderManager.waterTrackingEnabled = true
        reminderManager.dailyWaterGoal = 8
        reminderManager.waterUnit = .glasses
        
        // Set standard work hours
        reminderManager.setWorkHours(
            start: (9, 0),
            end: (17, 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "TouchGrass.hasCompletedOnboarding")
        
        // Request notifications if needed
        if notificationStatus == .notDetermined {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}