import SwiftUI
import EventKit

struct OnboardingHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Centered logo and title
            HStack(spacing: 15) {
                // Grass icon with sun
                ZStack {
                    // Grass blades background
                    HStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { index in
                            GrassBlade(delay: Double(index) * 0.1)
                        }
                    }
                    .frame(height: 45)
                    
                    // Sun/outdoor icon overlay
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow.opacity(0.8))
                        .offset(x: -30, y: -10)
                }
                .frame(width: 80)
                
                // Title
                Text("Touch Grass")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.green.opacity(0.9))
            }
            
            // Subtitle
            Text("Your guide to surviving the workday")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 15)
    }
}

struct GrassBlade: View {
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: 32)
            .cornerRadius(1.5)
            .rotationEffect(.degrees(isAnimating ? -5 : 5), anchor: .bottom)
            .animation(
                Animation.easeInOut(duration: 2 + Double.random(in: -0.5...0.5))
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct TouchGrassCalendarRow: View {
    let calendar: EKCalendar
    @ObservedObject var calendarManager: CalendarManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(calendar.cgColor))
                .frame(width: 8, height: 8)
            
            Text(calendar.title)
                .font(.system(size: 12))
                .foregroundColor(.primary)
            
            Spacer()
            
            if calendarManager.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            calendarManager.toggleCalendar(calendar)
        }
    }
}
