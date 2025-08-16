//
//  CalendarContextView.swift
//  TouchGrass
//
//  Calendar context display component
//

import SwiftUI

struct CalendarContextView: View {
    let calendarManager: CalendarManager?
    
    var body: some View {
        if let calManager = calendarManager,
           calManager.hasCalendarAccess,
           !calManager.selectedCalendarIdentifiers.isEmpty {
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                if calManager.isInMeeting, let currentEvent = calManager.currentEvent {
                    MeetingStatusBadge(
                        icon: "circle.fill",
                        iconColor: DesignSystem.Colors.error.opacity(0.6),
                        text: "In meeting until \(calManager.formatEventTime(currentEvent.endDate))"
                    )
                } else if let nextEvent = calManager.nextEvent,
                          let timeUntil = calManager.timeUntilNextEvent {
                    NextMeetingBadge(
                        timeUntil: calManager.formatTimeUntilEvent(timeUntil),
                        eventTitle: nextEvent.title ?? "Event"
                    )
                } else {
                    MeetingStatusBadge(
                        icon: "checkmark.circle",
                        iconColor: DesignSystem.Colors.success,
                        text: "No upcoming meetings - enjoy your break!"
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct MeetingStatusBadge: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xSmall) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(iconColor)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
        .accessibilityElement(children: .combine)
    }
}

struct NextMeetingBadge: View {
    let timeUntil: String
    let eventTitle: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "clock")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("Next meeting in \(timeUntil)")
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("•")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(eventTitle)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next meeting: \(eventTitle) in \(timeUntil)")
    }
}
