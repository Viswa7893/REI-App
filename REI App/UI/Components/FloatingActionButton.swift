import SwiftUI

struct FloatingActionButton: View {
    var icon: String
    var action: () -> Void
    var backgroundColor: Color = AppColors.primary
    var foregroundColor: Color = .white
    var size: CGFloat = 56
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .cornerRadius(size / 2)
                .shadow(color: backgroundColor.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                FloatingActionButton(
                    icon: "plus",
                    action: {}
                )
                
                FloatingActionButton(
                    icon: "pencil",
                    action: {},
                    backgroundColor: AppColors.secondary,
                    size: 48
                )
                
                FloatingActionButton(
                    icon: "trash",
                    action: {},
                    backgroundColor: AppColors.accent,
                    size: 64
                )
            }
        }
        .previewLayout(.sizeThatFits)
    }
} 