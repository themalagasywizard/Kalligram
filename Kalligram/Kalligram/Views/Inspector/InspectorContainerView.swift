import SwiftUI

struct InspectorContainerView: View {
    @Environment(AppState.self) private var appState

    var outlineVM: OutlineViewModel?
    var onSelectHeading: ((NSRange) -> Void)?

    var aiRewriteVM: AIRewriteViewModel?
    var hasEditorSelection: Bool = false
    var onAcceptRewrite: ((String) -> Void)?

    var researchVM: ResearchViewModel?
    var citationVM: CitationViewModel?
    var commentsVM: CommentsViewModel?
    var historyVM: VersionHistoryViewModel?
    var document: Document?
    var onInsertText: ((String) -> Void)?
    var onJumpToRange: ((NSRange) -> Void)?

    @State private var toolbarHeight: CGFloat = Spacing.editorToolbarHeight

    var body: some View {
        VStack(spacing: 0) {
            // Spacer reserves the tab bar area (actual tab bar is in overlay
            // to isolate it from content layout — prevents NSViewRepresentable
            // content like AIPanelView from destabilising the tab bar).
            Color.clear
                .frame(height: toolbarHeight)

            KDivider()

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .top) {
            inspectorTabBar
        }
        .background(ColorPalette.surfaceSecondary)
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            measureToolbarHeight()
        }
    }

    /// Read the window toolbar safe-area inset so the tab bar height
    /// matches exactly, aligning its bottom border with the main toolbar.
    private func measureToolbarHeight() {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow ?? NSApp.windows.first,
               let contentView = window.contentView {
                let inset = contentView.safeAreaInsets.top
                if inset > 0 {
                    toolbarHeight = inset
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var inspectorTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppState.InspectorTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(AnimationTokens.snappy) {
                        appState.inspectorTab = tab
                    }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Spacer(minLength: 0)

                        Image(systemName: tab.iconName)
                            .font(.system(size: 14))
                            .foregroundStyle(
                                appState.inspectorTab == tab
                                    ? ColorPalette.accentBlue
                                    : ColorPalette.textTertiary
                            )
                            .frame(height: 20)

                        Capsule()
                            .fill(appState.inspectorTab == tab ? ColorPalette.accentBlue : .clear)
                            .frame(height: 2)
                    }
                    .padding(.bottom, Spacing.xs)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(tab.label)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: toolbarHeight)
        .background(ColorPalette.surfaceSecondary)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch appState.inspectorTab {
        case .outline:
            if let outlineVM {
                OutlinePanelView(
                    outlineVM: outlineVM,
                    onSelectHeading: { range in
                        onSelectHeading?(range)
                    }
                )
            } else {
                InspectorPlaceholder(tab: "Outline", icon: SFSymbolTokens.outline)
            }
        case .format:
            if let document {
                FormatPanelView(document: document)
            } else {
                InspectorPlaceholder(tab: "Format", icon: SFSymbolTokens.format)
            }
        case .ai:
            if let aiRewriteVM {
                AIPanelView(
                    rewriteVM: aiRewriteVM,
                    hasSelection: hasEditorSelection,
                    onAcceptRewrite: { text in
                        onAcceptRewrite?(text)
                    }
                )
            } else {
                InspectorPlaceholder(tab: "AI", icon: SFSymbolTokens.ai)
            }
        case .research:
            if let researchVM, let citationVM {
                ResearchPanelView(
                    researchVM: researchVM,
                    citationVM: citationVM,
                    document: document,
                    onInsertCitation: { text in
                        onInsertText?(text)
                    }
                )
            } else {
                InspectorPlaceholder(tab: "Research", icon: SFSymbolTokens.research)
            }
        case .comments:
            if let commentsVM {
                CommentsPanelView(
                    commentsVM: commentsVM,
                    onJumpToComment: { range in
                        onJumpToRange?(range)
                    }
                )
            } else {
                InspectorPlaceholder(tab: "Comments", icon: SFSymbolTokens.comments)
            }
        case .history:
            if let historyVM {
                HistoryPanelView(
                    historyVM: historyVM,
                    document: document
                )
            } else {
                InspectorPlaceholder(tab: "History", icon: SFSymbolTokens.history)
            }
        }
    }
}

struct InspectorPlaceholder: View {
    let tab: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ColorPalette.textTertiary)
            Text(tab)
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.textSecondary)
            Text("Coming soon")
                .font(Typography.caption1)
                .foregroundStyle(ColorPalette.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
