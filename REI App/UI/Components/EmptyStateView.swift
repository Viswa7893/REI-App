import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var icon: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // Animated icon with visual effects
            ZStack {
                // Background glow
                Circle()
                    .fill(AppColors.secondary.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Icon with bounce effect
                Image(systemName: icon)
                    .font(.system(size: 70, weight: .light))
                    .foregroundColor(AppColors.secondary)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .rotationEffect(isAnimating ? .degrees(10) : .degrees(-10))
                    .animation(
                        Animation.spring(response: 0.5, dampingFraction: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(0.5),
                        value: isAnimating
                    )
                    .shadow(color: AppColors.secondary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, AppTheme.Spacing.m)
            .opacity(showContent ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: showContent)
            
            // Title with sliding animation
            Text(title)
                .font(.system(size: AppTheme.FontSize.title2, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppColors.secondary.opacity(0.1))
                        .shadow(color: AppColors.secondary.opacity(0.1), radius: 5, x: 0, y: 3)
                )
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: showContent)
            
            // Message with fade-in animation
            Text(message)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .opacity(showContent ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.4), value: showContent)
            
            if let actionTitle = actionTitle, let action = action {
                // Button with pulsing animation
                CustomButton(
                    title: actionTitle,
                    action: action,
                    style: .primary,
                    size: .medium
                )
                .padding(.top, AppTheme.Spacing.m)
                .frame(maxWidth: 250)
                .scaleEffect(isAnimating ? 1.03 : 1.0)
                .animation(
                    Animation.spring(response: 0.5, dampingFraction: 0.7)
                        .repeatForever(autoreverses: true)
                        .delay(1.5),
                    value: isAnimating
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: showContent)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Start animations with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            title: "No Reminders",
            message: "You don't have any reminders yet. Tap the button below to create your first reminder.",
            icon: "bell.badge",
            actionTitle: "Create Reminder",
            action: {}
        )
        .previewLayout(.sizeThatFits)
        
        EmptyStateView(
            title: "No Expenses",
            message: "Start tracking your expenses by adding your first expense.",
            icon: "creditcard"
        )
        .previewLayout(.sizeThatFits)
    }
} 