import SwiftUI

// MARK: - DestinationCard

struct DestinationCard: View {
    let destination: JWDestination
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(destination.accentColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: destination.systemImage)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(destination.accentColor)
                }

                Spacer(minLength: 0)

                // Texts
                Text(destination.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)

                Text(destination.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(destination.accentColor.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { isPressed = false } }
        )
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.surface)

            // Subtle accent gradient overlay
            LinearGradient(
                colors: [
                    destination.accentColor.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - WebLinkCard (used in PersonalStudyView)

struct WebLinkCard: View {
    let title: String
    let urlString: String
    let icon: String
    let tileColor: Color
    let iconColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tileColor)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(iconColor)
                    )

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { isPressed = false } }
        )
    }
}
