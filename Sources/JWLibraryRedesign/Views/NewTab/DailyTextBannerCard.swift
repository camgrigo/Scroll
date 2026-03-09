import SwiftUI

// MARK: - DailyTextBannerCard
//
// Full-width card shown at the top of the new tab page.
// Fetches live daily-text data (date + theme scripture) from WOL
// and displays it in a styled banner. Tapping opens the full daily-text page.

struct DailyTextBannerCard: View {

    @EnvironmentObject var tabManager: TabManager
    @State private var service = DailyTextService()
    @State private var isPressed = false

    private let accentColor = Color(hex: "#7B61FF")  // JW Library purple

    var body: some View {
        Button(action: openDailyText) {
            ZStack {
                // Card background
                cardBackground

                HStack(spacing: 0) {
                    // Left accent bar (matches screenshot style)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 4)
                        .padding(.vertical, 14)
                        .padding(.leading, 14)

                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        // Row 1: label + date + chevron
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(accentColor)

                            Text("Daily Text")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(accentColor)
                                .textCase(.uppercase)
                                .kerning(0.5)

                            Spacer()
                        }

                        // Row 2: date (bold, large) + chevron
                        HStack(alignment: .center) {
                            Group {
                                if service.isLoading && service.data == nil {
                                    Text("Loading…")
                                } else {
                                    Text(service.data?.dateString ?? DailyTextService.formatDate(Date()))
                                }
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.text)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(accentColor.opacity(0.7))
                        }

                        // Row 3: theme scripture
                        if let scripture = service.data?.themeScripture, !scripture.isEmpty {
                            Text(scripture)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if service.isLoading {
                            // Shimmer placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.textSecondary.opacity(0.15))
                                .frame(maxWidth: .infinity)
                                .frame(height: 13)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 16)
                    .padding(.vertical, 14)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { isPressed = false } }
        )
        .task { @MainActor in await service.fetchIfNeeded() }
    }

    // MARK: - Actions

    private func openDailyText() {
        tabManager.navigateActiveTab(
            to: JWDestination.dailyText.url,
            title: "Daily Text"
        )
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.surface)
            LinearGradient(
                colors: [accentColor.opacity(0.10), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
