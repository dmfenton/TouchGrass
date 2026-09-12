import FentonDesignSystem
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: WellnessStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.fentonTheme) private var theme

    var body: some View {
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "leaf") }
            ExerciseLibraryView().tabItem { Label("Move", systemImage: "figure.flexibility") }
            PreferencesView().tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(theme.palette(for: colorScheme).accent)
        .alert("Touch Grass", isPresented: Binding(
            get: { store.message != nil }, set: { if !$0 { store.message = nil } }
        )) { Button("OK") { store.message = nil } } message: { Text(store.message ?? "") }
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: WellnessStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.fentonTheme) private var theme
    @State private var outside = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FentonSpacing.large) {
                    Text("A little room to breathe.")
                        .font(FentonTypography.title)
                        .accessibilityAddTraits(.isHeader)
                    Text("Step away. Move a little. Come back refreshed.")
                        .foregroundStyle(.secondary)
                    FentonCard {
                        VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                            Label("Your next break", systemImage: "leaf.fill").font(.headline)
                            if let date = store.nextBreak {
                                Text(date, style: .time).font(.largeTitle.monospacedDigit())
                            } else {
                                Text(store.preferences.remindersEnabled ? "No break scheduled" : "Make space for a break")
                                    .font(.title2)
                            }
                            Button("Step outside", systemImage: "sun.max") { outside = true }
                                .buttonStyle(.borderedProminent)
                            HStack {
                                Button("Snooze 10 min") { store.pause(minutes: 10) }
                                Menu("Pause") {
                                    Button("For one hour") { store.pause(minutes: 60) }
                                    Button("For today") { store.pause(minutes: 24 * 60) }
                                    Button("Resume now") { store.pause(minutes: nil) }
                                }
                            }.buttonStyle(.bordered)
                            if let until = store.pausedUntil, until > Date() {
                                Text("Paused until \(until.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    OutdoorWeatherView()
                    FentonSectionHeader("Today")
                    FentonCard {
                        VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                            Label("Water", systemImage: "drop.fill").font(.headline)
                            Text("\(store.today.glasses) of \(store.preferences.waterGoal) glasses")
                            ProgressView(value: Double(min(store.today.glasses, store.preferences.waterGoal)),
                                         total: Double(store.preferences.waterGoal))
                            HStack {
                                Button("Add a glass", systemImage: "plus") { store.record(water: 1) }
                                    .buttonStyle(.borderedProminent)
                                Button("Undo") { store.record(water: -1) }
                                    .disabled(store.today.glasses == 0)
                            }
                            Text("One glass is 8 fl oz.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    FentonCard {
                        Label("\(store.today.breaks) breaks · \(store.streak) day streak", systemImage: "checkmark.circle")
                    }
                    if !store.preferences.remindersEnabled {
                        Button("Enable break reminders") { Task { await store.enableNotifications() } }
                            .buttonStyle(.bordered)
                    }
                }.padding(FentonSpacing.large)
            }
            .background(theme.palette(for: colorScheme).surface)
            .navigationTitle("Touch Grass")
            .sheet(isPresented: $outside) {
                OutsideBreakView()
            }
        }
    }
}

struct OutsideBreakView: View {
    @EnvironmentObject private var store: WellnessStore
    @Environment(\.dismiss) private var dismiss
    @State private var started = Date()
    var body: some View {
        NavigationStack {
            VStack(spacing: FentonSpacing.large) {
                Image(systemName: "sun.max").font(.system(size: 64)).foregroundStyle(.green)
                Text("Take it outside.").font(FentonTypography.title)
                Text("Look up. Let your eyes focus on something far away. Enjoy a few minutes of fresh air.")
                    .multilineTextAlignment(.center)
                Text(started, style: .timer).font(.largeTitle.monospacedDigit())
                Button("I took a break") { store.record(breaks: 1); dismiss() }
                    .buttonStyle(.borderedProminent)
            }.padding(FentonSpacing.large)
                .toolbar { Button("Close") { dismiss() } }
        }
    }
}
