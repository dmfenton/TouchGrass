//
//  ActivitySelectionView.swift
//  TouchGrass
//
//  Main activity selection component for TouchGrassMode
//

import SwiftUI

struct ActivitySelectionView: View {
    @ObservedObject var reminderManager: ReminderManager
    let onActivitySelected: (String, Bool) -> Void
    
    private let activities: [(icon: String, name: String, isGuided: Bool, shortcut: String)] = [
        ("clock", "1 Min Reset", true, "1"),
        ("figure.flexibility", "Exercises", true, "2"),
        ("brain.head.profile", "Meditation", true, "3"),
        ("leaf.circle", "Touch Grass", false, "4")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Header with smart suggestion
            HStack {
                Text("What would you like to do?")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if let suggestion = smartSuggestion {
                    Label(suggestion.text, systemImage: suggestion.icon)
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            // Activity grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: DesignSystem.Spacing.medium
            ) {
                ForEach(activities, id: \.name) { activity in
                    ActivityButton(
                        icon: activity.icon,
                        name: activity.name,
                        shortcut: activity.shortcut,
                        action: {
                            onActivitySelected(activity.name, activity.isGuided)
                        }
                    )
                }
            }
        }
    }
    
    private var smartSuggestion: (text: String, icon: String)? {
        guard let calManager = reminderManager.calendarManager,
              let timeUntil = calManager.timeUntilNextEvent else { return nil }
        
        if timeUntil >= 900 {  // 15+ minutes
            return ("Perfect for a walk!", "figure.walk")
        } else if timeUntil >= 300 {  // 5-15 minutes
            return ("Quick stretch time", "figure.flexibility")
        } else {  // Less than 5 minutes
            return ("Try breathing", "lungs")
        }
    }
}

struct ActivityButton: View {
    let icon: String
    let name: String
    let shortcut: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary.opacity(0.7))
                
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Text(name)
                        .font(DesignSystem.Typography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isHovered {
                        Text("⌘\(shortcut)")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, DesignSystem.Spacing.xSmall)
                            .padding(.vertical, DesignSystem.Spacing.xxSmall)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(DesignSystem.Colors.backgroundSecondary)
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(isHovered ? 
                          DesignSystem.Colors.tertiaryGreen : 
                          DesignSystem.Colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.micro) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
    }
}
