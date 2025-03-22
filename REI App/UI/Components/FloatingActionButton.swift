import SwiftUI

struct FloatingActionButton: View {
    var icon: String
    var action: () -> Void
    var backgroundColor: Color = AppColors.primary
    var foregroundColor: Color = .white
    var size: CGFloat = 60
    @State private var isPressed = false
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0
    @State private var shimmerOffset: CGFloat = -0.25
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Visual feedback
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            // Execute the action
            action()
            
            // Reset the pressed state with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // Ambient halo effect (subtle outer glow)
                Circle()
                    .fill(backgroundColor.opacity(0.15))
                    .frame(width: size * 1.3, height: size * 1.3)
                    .opacity(isPulsing ? 0.7 : 0.0)
                    .scaleEffect(isPulsing ? 1.1 : 0.95)
                
                // Main button background with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                backgroundColor.opacity(0.9),
                                backgroundColor,
                                backgroundColor.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Glossy overlay effect
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.5),
                                        .white.opacity(0.2),
                                        .white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(0.85)
                            .opacity(isPressed ? 0.5 : 0.7)
                    )
                    .overlay(
                        // Shimmer effect
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white.opacity(0.0), location: 0),
                                        .init(color: .white.opacity(0.3), location: 0.3),
                                        .init(color: .white.opacity(0.5), location: 0.5),
                                        .init(color: .white.opacity(0.3), location: 0.7),
                                        .init(color: .white.opacity(0.0), location: 1),
                                    ]),
                                    startPoint: UnitPoint(x: shimmerOffset, y: shimmerOffset),
                                    endPoint: UnitPoint(x: 1 + shimmerOffset, y: 1 + shimmerOffset)
                                )
                            )
                            .mask(Circle().stroke(lineWidth: size/3))
                    )
                    .overlay(
                        // Border highlight
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.6),
                                        backgroundColor.opacity(0.5)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: backgroundColor.opacity(0.5), radius: isPressed ? 5 : 8, x: 0, y: isPressed ? 2 : 4)
                    .shadow(color: backgroundColor.opacity(0.3), radius: 15, x: 0, y: 8)
                    .scaleEffect(isPressed ? 0.92 : 1.0)
                    .rotationEffect(Angle(degrees: isPressed ? -5 : 0))
                
                // Icon with animation
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(foregroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .opacity(isPressed ? 0.9 : 1.0)
                    .rotationEffect(Angle(degrees: isPressed ? -8 : 0))
                    .offset(y: isPressed ? 1 : 0)
            }
            .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start animations when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
                
                // Continuous rotation for the shimmer effect
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
            }
        }
        .onChange(of: shimmerOffset) { newValue in
            // Reset the shimmer position when it completes to create a continuous effect
            if newValue == 1.0 {
                shimmerOffset = -0.25
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
            }
        }
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                FloatingActionButton(
                    icon: "plus",
                    action: {}
                )
                
                FloatingActionButton(
                    icon: "pencil",
                    action: {},
                    backgroundColor: AppColors.secondary,
                    size: 54
                )
                
                FloatingActionButton(
                    icon: "trash",
                    action: {},
                    backgroundColor: AppColors.accent,
                    size: 68
                )
            }
        }
        .previewLayout(.sizeThatFits)
    }
} 