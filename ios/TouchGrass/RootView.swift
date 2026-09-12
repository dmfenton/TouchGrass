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
                    OutdoorWeatherView()
                    VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                        Text("Take a breather.").font(FentonTypography.smallTitle)
                        Text("A few minutes outside or a little movement.")
                            .foregroundStyle(.secondary)
                        Button { outside = true } label: {
                            Label("Step outside", systemImage: "sun.max")
                                .frame(maxWidth: .infinity).padding(.vertical, FentonSpacing.small)
                        }.buttonStyle(.borderedProminent)
                        if let routine = ExerciseData.allExerciseSets.first {
                            NavigationLink("Move indoors") { RoutineView(routine: routine) }
                                .frame(maxWidth: .infinity).padding(.vertical, FentonSpacing.small)
                        }
                        Divider()
                        reminderControls
                    }
                    .padding(FentonSpacing.medium)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: FentonRadius.medium))
                    VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                        HStack {
                            Label("Water", systemImage: "drop").font(.headline)
                            Spacer()
                            Text("\(store.today.glasses) of \(store.preferences.waterGoal) glasses")
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(min(store.today.glasses, store.preferences.waterGoal)),
                                     total: Double(store.preferences.waterGoal))
                        HStack {
                            Button("Add a glass", systemImage: "plus") { store.record(water: 1) }
                            Spacer()
                            Button("Undo") { store.record(water: -1) }.disabled(store.today.glasses == 0)
                        }.frame(minHeight: 44)
                    }
                    .padding(FentonSpacing.medium)
                    .background(Color(uiColor: .secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: FentonRadius.medium))
                    Text("\(store.today.breaks) \(store.today.breaks == 1 ? "break" : "breaks") · \(store.streak) workday streak")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if let through = store.scheduledThrough {
                        Text("""
                        Reminders planned through \(through.formatted(date: .abbreviated, time: .shortened)).
                        Open the app before then to keep them going.
                        """).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(FentonSpacing.medium)
            }
            .background(theme.palette(for: colorScheme).surface)
            .navigationTitle("Touch Grass")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $outside) { OutsideBreakView() }
        }
    }

    @ViewBuilder
    private var reminderControls: some View {
        if store.remindersActive {
            if let until = store.pausedUntil, until > Date() {
                Text("Paused until \(until.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
            } else if let date = store.nextBreak {
                Text("Next break · \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
            } else {
                Text("No upcoming breaks. Check your work hours in Settings.").font(.subheadline)
            }
            HStack {
                Button("Snooze 10 min") { store.snooze() }
                Spacer()
                Menu("Pause") {
                    Button("For one hour") { store.pause(minutes: 60) }
                    Button("For today") { store.pauseToday() }
                    Button("Resume now") { store.pause(minutes: nil) }
                }
            }.font(.subheadline).frame(minHeight: 44)
        } else {
            Button("Enable break reminders", systemImage: "bell") {
                Task { await store.enableNotifications() }
            }.font(.subheadline).frame(minHeight: 44)
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
                Text("Take three minutes outside.").font(FentonTypography.title)
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
