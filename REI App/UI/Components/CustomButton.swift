import SwiftUI

struct CustomButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case text
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    var title: String
    var action: () -> Void
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                }
                
                if let iconName = icon, !isLoading {
                    Image(systemName: iconName)
                        .font(iconFont)
                }
                
                Text(title)
                    .font(textFont)
                    .fontWeight(.medium)
            }
            .frame(height: height)
            .frame(maxWidth: size == .small ? nil : .infinity)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: style == .outline ? 1 : 0)
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled || isLoading)
    }
    
    // MARK: - Helper computed properties
    
    private var height: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return AppTheme.Spacing.s
        case .medium: return AppTheme.Spacing.m
        case .large: return AppTheme.Spacing.l
        }
    }
    
    private var textFont: Font {
        switch size {
        case .small: return .system(size: AppTheme.FontSize.footnote)
        case .medium: return .system(size: AppTheme.FontSize.body)
        case .large: return .system(size: AppTheme.FontSize.title3)
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .system(size: AppTheme.FontSize.footnote)
        case .medium: return .system(size: AppTheme.FontSize.body)
        case .large: return .system(size: AppTheme.FontSize.title3)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return AppColors.primary
        case .secondary: return AppColors.secondary
        case .outline, .text: return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary: return .white
        case .outline: return AppColors.primary
        case .text: return AppColors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline: return AppColors.primary
        default: return .clear
        }
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomButton(
                title: "Primary Button",
                action: {},
                style: .primary,
                icon: "plus"
            )
            
            CustomButton(
                title: "Secondary Button",
                action: {},
                style: .secondary
            )
            
            CustomButton(
                title: "Outline Button",
                action: {},
                style: .outline,
                size: .small
            )
            
            CustomButton(
                title: "Text Button",
                action: {},
                style: .text
            )
            
            CustomButton(
                title: "Loading Button",
                action: {},
                isLoading: true
            )
            
            CustomButton(
                title: "Disabled Button",
                action: {},
                isDisabled: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 