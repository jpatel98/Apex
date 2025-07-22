import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                Constants.Haptics.impact.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: Constants.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if isDisabled {
                        Color.gray
                    } else {
                        Constants.Colors.primaryGradient
                    }
                }
            )
            .cornerRadius(Constants.CornerRadius.medium)
            .opacity(isDisabled ? 0.6 : 1)
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .disabled(isLoading || isDisabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(Constants.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            Constants.Haptics.selection.selectionChanged()
            action()
        }) {
            HStack(spacing: Constants.Spacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(Constants.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(Constants.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}