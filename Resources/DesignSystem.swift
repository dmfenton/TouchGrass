//
//  DesignSystem.swift
//  TouchGrass
//
//  Centralized design tokens and constants for consistent UI
//

import SwiftUI

enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        static let primaryGreen = Color(red: 0.13, green: 0.37, blue: 0.13)
        static let secondaryGreen = Color.green.opacity(0.9)
        static let tertiaryGreen = Color.green.opacity(0.1)
        
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.7)
        
        static let backgroundPrimary = Color.clear
        static let backgroundSecondary = Color.black.opacity(0.05)
        static let backgroundTertiary = Color.green.opacity(0.05)
        
        static let divider = Color.secondary.opacity(0.2)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
    }
    
    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .bold)
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Semantic fonts
        static let heading1 = largeTitle
        static let heading2 = title
        static let heading3 = title2
        static let bodyLarge = Font.system(size: 15)
        static let bodyRegular = body
        static let bodySmall = callout
        static let label = caption
        static let labelSmall = caption2
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
        static let xxxLarge: CGFloat = 32
        
        // Semantic spacing
        static let componentPadding = medium
        static let sectionSpacing = large
        static let viewPadding = xLarge
    }
    
    // MARK: - Sizing
    enum Sizing {
        static let buttonHeight: CGFloat = 36
        static let buttonHeightLarge: CGFloat = 44
        static let buttonHeightSmall: CGFloat = 28
        
        static let iconSize: CGFloat = 16
        static let iconSizeLarge: CGFloat = 24
        static let iconSizeSmall: CGFloat = 12
        
        static let menuWidth: CGFloat = 400
        static let settingsWidth: CGFloat = 480
        static let settingsHeight: CGFloat = 720
        static let exerciseViewWidth: CGFloat = 500
        static let exerciseViewHeight: CGFloat = 520
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        
        // Semantic radius
        static let button = small
        static let card = large
        static let input = small
    }
    
    // MARK: - Animation
    enum Animation {
        static let microDuration: Double = 0.15
        static let standardDuration: Double = 0.3
        static let emphasisDuration: Double = 0.5
        
        static let micro = SwiftUI.Animation.easeInOut(duration: microDuration)
        static let standard = SwiftUI.Animation.easeInOut(duration: standardDuration)
        static let emphasis = SwiftUI.Animation.easeInOut(duration: emphasisDuration)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Shadows
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    enum Shadow {
        static let subtle = ShadowStyle(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let standard = ShadowStyle(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let elevated = ShadowStyle(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyRegular)
            .foregroundColor(.white)
            .frame(height: DesignSystem.Sizing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(isEnabled ? DesignSystem.Colors.primaryGreen : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyRegular)
            .foregroundColor(DesignSystem.Colors.primaryGreen)
            .frame(height: DesignSystem.Sizing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.primaryGreen, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                            .fill(configuration.isPressed ? DesignSystem.Colors.tertiaryGreen : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyRegular)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(configuration.isPressed ? DesignSystem.Colors.backgroundSecondary : Color.clear)
            )
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
    }
}

struct CardButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(isSelected ? DesignSystem.Colors.tertiaryGreen : DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .stroke(isSelected ? DesignSystem.Colors.primaryGreen : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.micro, value: configuration.isPressed)
            .animation(DesignSystem.Animation.standard, value: isSelected)
    }
}

// MARK: - View Extensions

extension View {
    func primaryButton() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func tertiaryButton() -> some View {
        self.buttonStyle(TertiaryButtonStyle())
    }
    
    func cardButton(isSelected: Bool = false) -> some View {
        self.buttonStyle(CardButtonStyle(isSelected: isSelected))
    }
}

// MARK: - Loading State View

struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
            
            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.xLarge)
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String = "Something went wrong",
         message: String,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: DesignSystem.Sizing.iconSizeLarge))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .secondaryButton()
                    .frame(width: 120)
            }
        }
        .padding(DesignSystem.Spacing.xLarge)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: DesignSystem.Sizing.iconSizeLarge))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xLarge)
    }
}
