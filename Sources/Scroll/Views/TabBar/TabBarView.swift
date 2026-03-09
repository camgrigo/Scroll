import SwiftUI

// MARK: - TabBarView

struct TabBarView: View {
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(tabManager.tabs) { tab in
                    TabChip(tab: tab)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }

                // New tab button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        _ = tabManager.newTab()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppTheme.surface.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .animation(.spring(response: 0.3), value: tabManager.activeTabID)
        }
        .frame(height: AppTheme.tabBarHeight)
        .background(.ultraThinMaterial)
    }
}
