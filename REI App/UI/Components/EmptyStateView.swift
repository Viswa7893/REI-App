import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var icon: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(AppColors.secondary.opacity(0.7))
                .padding(.bottom, AppTheme.Spacing.s)
            
            Text(title)
                .font(.system(size: AppTheme.FontSize.title2, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.system(size: AppTheme.FontSize.body))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            if let actionTitle = actionTitle, let action = action {
                CustomButton(
                    title: actionTitle,
                    action: action,
                    style: .primary,
                    size: .medium
                )
                .padding(.top, AppTheme.Spacing.s)
                .frame(maxWidth: 250)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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