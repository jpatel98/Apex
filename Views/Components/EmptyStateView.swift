import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Constants.Colors.primaryGradient)
                .padding(.bottom, Constants.Spacing.small)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.extraLarge)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(minWidth: 120)
                        .padding(.horizontal, Constants.Spacing.large)
                        .padding(.vertical, Constants.Spacing.medium)
                        .background(Constants.Colors.primaryGradient)
                        .cornerRadius(Constants.CornerRadius.full)
                }
                .padding(.top, Constants.Spacing.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Constants.Spacing.extraLarge)
    }
}