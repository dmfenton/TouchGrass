import SwiftUI

struct WaterView: View {
    @ObservedObject var manager: iOSReminderManager
    @State private var showingUnitPicker = false
    
    var waterProgress: Double {
        Double(manager.currentWaterIntake) / Double(manager.dailyWaterGoal)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Water Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: min(waterProgress, 1.0))
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: waterProgress)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("\(manager.currentWaterIntake)")
                                .font(.system(size: 48, weight: .bold))
                            
                            Text("of \(manager.dailyWaterGoal) \(manager.waterUnit.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Quick Add Buttons
                    VStack(spacing: 16) {
                        Text("Quick Add")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach([1, 2, 3], id: \.self) { amount in
                                Button(action: {
                                    withAnimation {
                                        manager.logWater(amount)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                        Text("+\(amount)")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Stats
                    VStack(spacing: 16) {
                        Text("Hydration Stats")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            StatCard(
                                icon: "flame.fill",
                                value: "\(manager.waterStreak)",
                                label: "Day Streak",
                                color: .orange
                            )
                            
                            StatCard(
                                icon: "percent",
                                value: String(format: "%.0f%%", waterProgress * 100),
                                label: "Today",
                                color: .blue
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                        
                        // Daily Goal
                        HStack {
                            Text("Daily Goal")
                            Spacer()
                            Stepper(
                                "\(manager.dailyWaterGoal) \(manager.waterUnit.rawValue)",
                                value: $manager.dailyWaterGoal,
                                in: 1...20
                            )
                        }
                        
                        // Unit Selection
                        HStack {
                            Text("Unit")
                            Spacer()
                            Picker("Unit", selection: $manager.waterUnit) {
                                ForEach(WaterUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 180)
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
            .navigationTitle("Water Tracking")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 25))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(label)
                .font(.caption)
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