import SwiftUI

// MARK: - TabChip

struct TabChip: View {
    let tab: TabItem
    @EnvironmentObject var tabManager: TabManager

    private var isActive: Bool { tabManager.activeTabID == tab.id }

    var body: some View {
        HStack(spacing: 6) {
            // Favicon / icon
            Image(systemName: tab.faviconSystemImage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textSecondary)

            // Title
            Text(tab.title)
                .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? AppTheme.text : AppTheme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)

            // Close button
            Button {
                withAnimation(.spring(response: 0.25)) {
                    tabManager.closeTab(tab)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 80, maxWidth: 160)
        .background(chipBackground)
        .clipShape(Capsule())
        .overlay(
            // Active gold underline
            isActive
                ? Capsule().stroke(AppTheme.accent, lineWidth: 1.5)
                : Capsule().stroke(Color.clear, lineWidth: 0)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                tabManager.selectTab(tab)
            }
        }
        .contextMenu {
            Button("Close Tab", role: .destructive) {
                tabManager.closeTab(tab)
            }
            Button("New Tab") {
                _ = tabManager.newTab()
            }
        }
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isActive {
            Capsule()
                .fill(AppTheme.surface)
        } else {
            Capsule()
                .fill(AppTheme.surface.opacity(0.5))
        }
    }
}
