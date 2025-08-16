//
//  CompletionView.swift
//  TouchGrass
//
//  Activity completion celebration view
//

import SwiftUI

struct CompletionView: View {
    let completedActivity: String
    @State private var animateCheckmark = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.success)
                .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                .opacity(animateCheckmark ? 1.0 : 0.0)
                .animation(
                    DesignSystem.Animation.spring
                        .delay(0.1),
                    value: animateCheckmark
                )
            
            Text("Great job!")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("You completed: \(completedActivity)")
                .font(DesignSystem.Typography.bodyRegular)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            animateCheckmark = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Great job! You completed \(completedActivity)")
    }
}
