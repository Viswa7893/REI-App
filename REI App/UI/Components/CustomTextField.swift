import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var leadingIcon: String? = nil
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(.system(size: AppTheme.FontSize.subheadline))
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: AppTheme.Spacing.xs) {
                if let iconName = leadingIcon {
                    Image(systemName: iconName)
                        .foregroundColor(isEditing ? AppColors.primary : AppColors.secondaryText)
                        .frame(width: 24, height: 24)
                }
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                } else {
                    TextField(placeholder, text: $text, onEditingChanged: { editing in
                        isEditing = editing
                    })
                    .keyboardType(keyboardType)
                }
            }
            .padding(AppTheme.Spacing.s)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isEditing ? AppColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTextField(
                title: "Name",
                placeholder: "Enter your name",
                text: .constant("John Doe")
            )
            
            CustomTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant(""),
                keyboardType: .emailAddress,
                leadingIcon: "envelope"
            )
            
            CustomTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: .constant(""),
                isSecure: true,
                leadingIcon: "lock"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 