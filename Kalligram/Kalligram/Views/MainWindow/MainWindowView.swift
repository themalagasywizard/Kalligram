import SwiftUI
import SwiftData

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allDocuments: [Document]
    @State private var aiRewriteVM = AIRewriteViewModel()
    @State private var researchVM = ResearchViewModel()
    @State private var citationVM = CitationViewModel()
    @State private var commentsVM = CommentsViewModel()
    @State private var historyVM = VersionHistoryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarColumn
        } detail: {
            editorColumn
        }
        .inspector(isPresented: $state.isInspectorVisible) {
            inspectorColumn
        }
        .toolbar {
            MainToolbar()
        }
        .toolbar(removing: .sidebarToggle)
        .onChange(of: appState.isSidebarVisible) { _, _ in
            updateColumnVisibility()
        }
        .onAppear {
            updateColumnVisibility()
            // Clean up stale open document IDs from previous session
            let validIDs = Set(allDocuments.map { $0.id })
            appState.openDocumentIDs = appState.openDocumentIDs.filter { validIDs.contains($0) }

            // Restore last selected document
            if appViewModel.selectedDocument == nil,
               let lastID = appState.lastSelectedDocumentID,
               let doc = allDocuments.first(where: { $0.id == lastID }) {
                appViewModel.selectDocument(doc)
            }
        }
        .sheet(isPresented: $state.isNewDocumentSheetPresented) {
            NewDocumentSheet()
                .environment(appViewModel)
        }
        .sheet(isPresented: $state.isExportSheetPresented) {
            if let document = appViewModel.selectedDocument {
                ExportSheet(
                    document: document,
                    attributedString: exportAttributedString(from: document)
                )
            }
        }
    }

    private func updateColumnVisibility() {
        columnVisibility = appState.isSidebarVisible ? .all : .detailOnly
    }

    private func exportAttributedString(from document: Document) -> NSAttributedString {
        if let rtfData = document.contentRTFData,
           let attrString = NSAttributedString.fromRTFData(rtfData) {
            return attrString
        }
        return NSAttributedString(string: document.contentPlainText)
    }

    @ViewBuilder
    private var sidebarColumn: some View {
        SidebarView()
            .navigationSplitViewColumnWidth(
                min: Spacing.sidebarMinWidth,
                ideal: Spacing.sidebarIdealWidth,
                max: Spacing.sidebarMaxWidth
            )
    }

    @ViewBuilder
    private var editorColumn: some View {
        EditorContainerView(aiRewriteVM: aiRewriteVM)
    }

    @ViewBuilder
    private var inspectorColumn: some View {
        InspectorContainerView(
            aiRewriteVM: aiRewriteVM,
            hasEditorSelection: !aiRewriteVM.selectedText.isEmpty,
            onAcceptRewrite: { text in
                appState.pendingInsertText = text
            },
            researchVM: researchVM,
            citationVM: citationVM,
            commentsVM: commentsVM,
            historyVM: historyVM,
            document: appViewModel.selectedDocument
        )
        .inspectorColumnWidth(
            min: Spacing.inspectorMinWidth,
            ideal: Spacing.inspectorIdealWidth,
            max: Spacing.inspectorMaxWidth
        )
    }
}
