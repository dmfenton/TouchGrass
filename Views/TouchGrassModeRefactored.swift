//
//  TouchGrassModeRefactored.swift
//  TouchGrass
//
//  Refactored TouchGrassMode with improved architecture
//

import SwiftUI

struct TouchGrassModeRefactored: View {
    @FocusState private var isFocused: Bool
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    
    // View state management
    @State private var viewState: ViewState = .activities
    @State private var completedActivity: String? = nil
    @State private var selectedExerciseSet: ExerciseSet? = nil
    
    enum ViewState {
        case activities
        case exerciseMenu
        case exerciseSet
        case completion
    }
    
    private func closeMenuBar() {
        NSApplication.shared.keyWindow?.close()
    }
    
    private func handleActivityTap(_ activity: String, isGuided: Bool) {
        if isGuided {
            switch activity {
            case "1 Min Reset":
                withAnimation(DesignSystem.Animation.standard) {
                    selectedExerciseSet = ExerciseData.oneMinuteBreak
                    viewState = .exerciseSet
                }
            case "Exercises":
                withAnimation(DesignSystem.Animation.standard) {
                    viewState = .exerciseMenu
                }
            case "Meditation":
                withAnimation(DesignSystem.Animation.standard) {
                    selectedExerciseSet = ExerciseData.breathingExercise
                    viewState = .exerciseSet
                }
            default:
                break
            }
        } else {
            completeActivity(activity)
        }
    }
    
    private func completeActivity(_ activity: String) {
        reminderManager.completeActivity(activity)
        reminderManager.completeBreak()
        completedActivity = activity
        viewState = .completion
        
        // Auto-close after showing completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            closeMenuBar()
            dismiss()
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xLarge) {
            // Header
            headerView
            
            // Calendar context
            CalendarContextView(calendarManager: reminderManager.calendarManager)
            
            Divider()
            
            // Main content area
            mainContent
            
            Divider()
            
            // Water tracking
            WaterTrackingBar(reminderManager: reminderManager)
            
            Spacer()
            
            // Bottom actions
            bottomActions
        }
        .padding(.horizontal, DesignSystem.Spacing.xxLarge)
        .padding(.bottom, DesignSystem.Spacing.xxLarge)
        .padding(.top, DesignSystem.Spacing.xxxLarge)
        .frame(width: DesignSystem.Sizing.menuWidth)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Refresh calendar data when window opens
            reminderManager.calendarManager?.updateCurrentAndNextEvents()
            
            // Reset active reminder state when Touch Grass window opens
            if reminderManager.hasActiveReminder {
                reminderManager.hasActiveReminder = false
            }
        }
        .animation(DesignSystem.Animation.standard, value: viewState)
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            GrassIcon(isActive: false, size: 24)
                .foregroundColor(DesignSystem.Colors.textPrimary.opacity(0.8))
            
            Text("Time to Touch Grass")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Time to Touch Grass")
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch viewState {
        case .activities:
            ActivitySelectionView(
                reminderManager: reminderManager,
                onActivitySelected: handleActivityTap
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            
        case .exerciseMenu:
            ExerciseMenuView(
                onBack: {
                    withAnimation(DesignSystem.Animation.standard) {
                        viewState = .activities
                    }
                },
                onExerciseSelected: { exerciseSet in
                    selectedExerciseSet = exerciseSet
                    viewState = .exerciseSet
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            
        case .exerciseSet:
            if let exerciseSet = selectedExerciseSet {
                ExerciseSetView(
                    exerciseSet: exerciseSet,
                    reminderManager: reminderManager,
                    onClose: {
                        selectedExerciseSet = nil
                        viewState = .activities
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
            
        case .completion:
            if let activity = completedActivity {
                CompletionView(completedActivity: activity)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    private var bottomActions: some View {
        if viewState != .completion && viewState != .exerciseSet {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Button(action: {
                    reminderManager.snoozeReminder()
                    closeMenuBar()
                    dismiss()
                }) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "clock")
                            .font(DesignSystem.Typography.caption)
                        Text("Snooze 5 min")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignSystem.Colors.warning)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Snooze reminder for 5 minutes")
                
                Spacer()
                
                Button(action: {
                    reminderManager.hasActiveReminder = false
                    reminderManager.scheduleNextTick()
                    closeMenuBar()
                    dismiss()
                }) {
                    Text("Skip for now")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip this reminder")
            }
        }
    }
}
