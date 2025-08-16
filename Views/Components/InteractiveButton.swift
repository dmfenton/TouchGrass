//
//  InteractiveButton.swift
//  TouchGrass
//
//  Enhanced button with micro-interactions and feedback
//

import SwiftUI

struct InteractivePrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyRegular)
            .foregroundColor(.white)
            .frame(height: DesignSystem.Sizing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(
                        LinearGradient(
                            colors: [
                                isEnabled ? DesignSystem.Colors.primaryGreen : Color.gray,
                                isEnabled ? DesignSystem.Colors.primaryGreen.opacity(0.8) : Color.gray.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: configuration.isPressed ? .clear : DesignSystem.Colors.primaryGreen.opacity(0.3),
                        radius: isHovered ? 8 : 4,
                        x: 0,
                        y: configuration.isPressed ? 0 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.micro, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { hovering in
                withAnimation(DesignSystem.Animation.micro) {
                    isHovered = hovering && isEnabled
                }
            }
    }
}

struct InteractiveSecondaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyRegular)
            .foregroundColor(isHovered ? .white : DesignSystem.Colors.primaryGreen)
            .frame(height: DesignSystem.Sizing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(
                        DesignSystem.Colors.primaryGreen,
                        lineWidth: isHovered ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(
                                isHovered ? 
                                DesignSystem.Colors.primaryGreen :
                                (configuration.isPressed ? 
                                 DesignSystem.Colors.tertiaryGreen : 
                                 Color.clear)
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.01 : 1.0))
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.standard, value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.6)
            .onHover { hovering in
                withAnimation(DesignSystem.Animation.standard) {
                    isHovered = hovering && isEnabled
                }
            }
    }
}

struct InteractiveCardButton: ButtonStyle {
    var isSelected: Bool = false
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(
                        isSelected ? 
                        DesignSystem.Colors.tertiaryGreen :
                        (isHovered ? 
                         DesignSystem.Colors.backgroundSecondary.opacity(1.5) :
                         DesignSystem.Colors.backgroundSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .stroke(
                                isSelected ? 
                                DesignSystem.Colors.primaryGreen :
                                (isHovered ? 
                                 DesignSystem.Colors.primaryGreen.opacity(0.3) :
                                 Color.clear),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isHovered ? DesignSystem.Colors.primaryGreen.opacity(0.1) : .clear,
                        radius: isHovered ? 8 : 0,
                        x: 0,
                        y: isHovered ? 2 : 0
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
            .animation(DesignSystem.Animation.standard, value: isHovered)
            .animation(DesignSystem.Animation.standard, value: isSelected)
            .onHover { hovering in
                withAnimation(DesignSystem.Animation.standard) {
                    isHovered = hovering
                }
            }
    }
}

// Ripple effect button for special actions
struct RippleButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    
    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Trigger ripple animation
            withAnimation(DesignSystem.Animation.emphasis) {
                rippleScale = 2.0
                rippleOpacity = 0.3
            }
            
            // Reset after animation
            withAnimation(DesignSystem.Animation.emphasis.delay(0.2)) {
                rippleOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
            
            // Reset scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                rippleScale = 0
            }
        }) {
            ZStack {
                // Ripple effect
                Circle()
                    .fill(DesignSystem.Colors.primaryGreen)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                
                HStack(spacing: DesignSystem.Spacing.small) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .font(DesignSystem.Typography.bodyRegular)
                    }
                    Text(title)
                        .font(DesignSystem.Typography.bodyRegular)
                }
                .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(height: DesignSystem.Sizing.buttonHeight)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// View extensions for enhanced buttons
extension View {
    func interactivePrimaryButton() -> some View {
        self.buttonStyle(InteractivePrimaryButton())
    }
    
    func interactiveSecondaryButton() -> some View {
        self.buttonStyle(InteractiveSecondaryButton())
    }
    
    func interactiveCardButton(isSelected: Bool = false) -> some View {
        self.buttonStyle(InteractiveCardButton(isSelected: isSelected))
    }
}
