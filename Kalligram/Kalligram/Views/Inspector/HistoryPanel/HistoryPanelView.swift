import SwiftUI
import SwiftData

struct HistoryPanelView: View {
    let historyVM: VersionHistoryViewModel
    let document: Document?

    @Environment(\.modelContext) private var modelContext
    @State private var isBranchSheetPresented = false
    @State private var branchTitle: String = ""
    @State private var branchSourceSnapshot: ProjectSnapshot?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                HStack {
                    Image(systemName: SFSymbolTokens.history)
                        .foregroundStyle(ColorPalette.accentBlue)
                    Text("Version History")
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.textPrimary)
                    Spacer()
                    if activeProject != nil {
                        Button {
                            guard let project = projectForActions() else { return }
                            historyVM.createManualSnapshot(for: project, sourceDocument: document, modelContext: modelContext)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 12))
                                Text("Snapshot")
                                    .font(Typography.caption2)
                            }
                            .foregroundStyle(ColorPalette.accentBlue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let project = activeProject {
                    branchPickerRow(for: project)

                    if historyVM.snapshots.isEmpty {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: SFSymbolTokens.history)
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(ColorPalette.textTertiary.opacity(0.5))
                            Text("No version history yet")
                                .font(Typography.bodySmall)
                                .foregroundStyle(ColorPalette.textTertiary)
                            Text("Create a snapshot to start tracking your project history.")
                                .font(Typography.caption1)
                                .foregroundStyle(ColorPalette.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxxl)
                    } else {
                        // Timeline
                        ForEach(historyVM.snapshots, id: \.id) { snapshot in
                            HistorySnapshotRow(
                                snapshot: snapshot,
                                isSelected: historyVM.selectedSnapshot?.id == snapshot.id,
                                isHead: historyVM.headSnapshotID(in: activeProject) == snapshot.id,
                                iconName: historyVM.triggerTypeIcon(snapshot.triggerType),
                                onSelect: {
                                    historyVM.selectedSnapshot = snapshot
                                },
                                onRestore: {
                                    historyVM.restore(snapshot, in: project, modelContext: modelContext)
                                },
                                onBranch: {
                                    branchSourceSnapshot = snapshot
                                    branchTitle = suggestedBranchTitle()
                                    isBranchSheetPresented = true
                                }
                            )
                        }
                    }
                } else {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: SFSymbolTokens.history)
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(ColorPalette.textTertiary.opacity(0.5))
                        Text("No project selected")
                            .font(Typography.bodySmall)
                            .foregroundStyle(ColorPalette.textTertiary)
                        Text("Open a document to enable project history.")
                            .font(Typography.caption1)
                            .foregroundStyle(ColorPalette.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxxl)
                }
            }
            .padding(Spacing.lg)
        }
        .onAppear {
            ensureProjectIfNeeded()
            if let project = activeProject {
                historyVM.load(for: project, modelContext: modelContext)
            }
        }
        .onChange(of: document?.id) { _, _ in
            ensureProjectIfNeeded()
            if let project = activeProject {
                historyVM.load(for: project, modelContext: modelContext)
            }
        }
        .onChange(of: document?.project?.id) { _, _ in
            ensureProjectIfNeeded()
            if let project = activeProject {
                historyVM.load(for: project, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $isBranchSheetPresented) {
            BranchFromSnapshotSheet(
                title: $branchTitle,
                onCancel: {
                    isBranchSheetPresented = false
                },
                onCreate: {
                    guard let snapshot = branchSourceSnapshot,
                          let project = projectForActions() else { return }
                    historyVM.createBranch(from: snapshot, name: branchTitle, project: project, modelContext: modelContext)
                    isBranchSheetPresented = false
                }
            )
        }
    }

    private var activeProject: Project? {
        document?.project
    }

    private func projectForActions() -> Project? {
        if let project = document?.project {
            return project
        }
        if let document {
            return ProjectSnapshotService.ensureProject(for: document, modelContext: modelContext)
        }
        return nil
    }

    private func ensureProjectIfNeeded() {
        guard let document, document.project == nil else { return }
        _ = ProjectSnapshotService.ensureProject(for: document, modelContext: modelContext)
    }

    @ViewBuilder
    private func branchPickerRow(for project: Project) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: SFSymbolTokens.branch)
                .foregroundStyle(ColorPalette.textTertiary)
            Picker("Branch", selection: Binding(
                get: { historyVM.activeBranch?.id ?? project.activeBranchID },
                set: { newValue in
                    guard let newValue,
                          let branch = project.branches.first(where: { $0.id == newValue }) else { return }
                    historyVM.checkoutBranch(branch, in: project, modelContext: modelContext)
                }
            )) {
                ForEach(historyVM.branches, id: \.id) { branch in
                    Text(branch.name).tag(Optional(branch.id))
                }
            }
            .pickerStyle(.menu)

            Spacer()

            Button {
                branchSourceSnapshot = historyVM.selectedSnapshot ?? historyVM.snapshots.first
                branchTitle = suggestedBranchTitle()
                isBranchSheetPresented = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("New Branch")
                        .font(Typography.caption2)
                }
                .foregroundStyle(ColorPalette.textPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(ColorPalette.surfaceTertiary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(historyVM.snapshots.isEmpty)
        }
    }

    private func suggestedBranchTitle() -> String {
        let base = document?.project?.name ?? document?.title ?? "Untitled"
        return "\(base) — Branch"
    }
}
