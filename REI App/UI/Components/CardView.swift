import SwiftUI

struct CardView<Content: View>: View {
    var content: Content
    var padding: EdgeInsets = EdgeInsets(
        top: AppTheme.Spacing.m,
        leading: AppTheme.Spacing.m,
        bottom: AppTheme.Spacing.m,
        trailing: AppTheme.Spacing.m
    )
    var cornerRadius: CGFloat = AppTheme.CornerRadius.medium
    var shadowRadius: CGFloat = 4
    var backgroundColor: Color = AppColors.secondaryBackground
    
    // Basic initializer
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    // Comprehensive initializer with optional parameters
    init<C: View>(
        padding: EdgeInsets? = nil,
        cornerRadius: CGFloat? = nil,
        shadowRadius: CGFloat? = nil,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> C
    ) where Content == C {
        self.content = content()
        if let padding = padding {
            self.padding = padding
        }
        if let cornerRadius = cornerRadius {
            self.cornerRadius = cornerRadius
        }
        if let shadowRadius = shadowRadius {
            self.shadowRadius = shadowRadius
        }
        if let backgroundColor = backgroundColor {
            self.backgroundColor = backgroundColor
        }
    }
    
    // Backward compatibility initializer for old "color" and "elevation" parameters
    init<C: View>(
        color: Color,
        elevation: CGFloat = 4,
        @ViewBuilder content: () -> C
    ) where Content == C {
        self.content = content()
        self.backgroundColor = color
        self.shadowRadius = elevation
    }
    
    // Single parameter initializer - most common use case
    init<C: View>(
        shadowRadius: CGFloat,
        @ViewBuilder content: () -> C
    ) where Content == C {
        self.content = content()
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: shadowRadius,
                x: 0,
                y: 2
            )
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Default Card")
                        .font(.headline)
                    Text("This is a default card with standard styling")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            CardView(
                padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
                cornerRadius: 16,
                shadowRadius: 8,
                backgroundColor: AppColors.background
            ) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.accent)
                    Text("Custom Card")
                        .fontWeight(.semibold)
                }
            }
            
            // Using the backward compatibility initializer
            CardView(color: Color(.systemBackground), elevation: 3) {
                Text("Card with color and elevation parameters")
            }
            
            // Using the shadowRadius only initializer
            CardView(shadowRadius: 0) {
                Text("Card without shadow")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 