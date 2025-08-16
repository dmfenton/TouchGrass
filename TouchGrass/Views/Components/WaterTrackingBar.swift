//
//  WaterTrackingBar.swift
//  TouchGrass
//
//  Consistent water tracking bar component
//

import SwiftUI

struct WaterTrackingBar: View {
    @ObservedObject var reminderManager: ReminderManager
    @State private var buttonPressed = false
    
    private var waterColor: Color {
        Color(red: 0.0, green: 0.5, blue: 1.0)
    }
    
    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .font(DesignSystem.Typography.bodyRegular)
                .foregroundColor(waterColor)
            
            Text("\(reminderManager.currentWaterIntake * 8) / 64 oz")
                .font(DesignSystem.Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Button(action: {
                withAnimation(DesignSystem.Animation.micro) {
                    buttonPressed = true
                    reminderManager.logWater(1)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    buttonPressed = false
                }
            }) {
                Text("+8oz")
                    .font(DesignSystem.Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(waterColor)
                    )
            }
            .buttonStyle(.plain)
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.micro, value: buttonPressed)
            .accessibilityLabel("Add 8 ounces of water")
            .accessibilityHint("Current: \(reminderManager.currentWaterIntake * 8) of 64 ounces")
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}
