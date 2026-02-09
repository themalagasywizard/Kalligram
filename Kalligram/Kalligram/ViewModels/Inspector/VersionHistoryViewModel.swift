import SwiftUI
import SwiftData

@Observable
final class VersionHistoryViewModel {
    var branches: [ProjectBranch] = []
    var activeBranch: ProjectBranch?
    var snapshots: [ProjectSnapshot] = []
    var selectedSnapshot: ProjectSnapshot?

    func load(for project: Project, modelContext: ModelContext) {
        activeBranch = ProjectSnapshotService.ensureDefaultBranch(for: project, modelContext: modelContext)
        branches = project.branches.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if let active = activeBranch, project.activeBranchID != active.id {
            project.activeBranchID = active.id
        }
        snapshots = snapshotsForActiveBranch(in: project)
        if selectedSnapshot == nil {
            selectedSnapshot = snapshots.first
        }
    }

    func createManualSnapshot(for project: Project, sourceDocument: Document?, modelContext: ModelContext) {
        let snapshot = ProjectSnapshotService.createSnapshot(
            for: project,
            sourceDocument: sourceDocument,
            triggerType: "snapshot",
            modelContext: modelContext
        )
        refreshSnapshots(for: project, selecting: snapshot)
    }

    func restore(_ snapshot: ProjectSnapshot, in project: Project, modelContext: ModelContext) {
        ProjectSnapshotService.restore(snapshot: snapshot, to: project, modelContext: modelContext)
        if let active = activeBranch {
            active.headSnapshotID = snapshot.id
        } else if let activeID = project.activeBranchID,
                  let branch = project.branches.first(where: { $0.id == activeID }) {
            branch.headSnapshotID = snapshot.id
            activeBranch = branch
        }
        refreshSnapshots(for: project, selecting: snapshot)
    }

    func createBranch(from snapshot: ProjectSnapshot, name: String, project: Project, modelContext: ModelContext) {
        _ = ProjectSnapshotService.createBranch(from: snapshot, name: name, project: project, modelContext: modelContext)
        load(for: project, modelContext: modelContext)
    }

    func checkoutBranch(_ branch: ProjectBranch, in project: Project, modelContext: ModelContext) {
        activeBranch = branch
        _ = ProjectSnapshotService.checkoutBranch(branch, in: project, modelContext: modelContext)
        snapshots = snapshotsForActiveBranch(in: project)
        selectedSnapshot = snapshots.first
    }

    func headSnapshotID(in project: Project?) -> UUID? {
        guard let project else { return nil }
        if let active = activeBranch {
            return active.headSnapshotID
        }
        if let activeID = project.activeBranchID,
           let branch = project.branches.first(where: { $0.id == activeID }) {
            return branch.headSnapshotID
        }
        return nil
    }

    var triggerTypeIcon: (String) -> String = { triggerType in
        switch triggerType {
        case "snapshot": SFSymbolTokens.manualSave
        case "ai_action": SFSymbolTokens.aiAction
        default: SFSymbolTokens.manualSave
        }
    }

    private func snapshotsForActiveBranch(in project: Project) -> [ProjectSnapshot] {
        guard let branch = activeBranch ?? project.branches.first(where: { $0.id == project.activeBranchID }) else {
            return []
        }
        let map = Dictionary(uniqueKeysWithValues: project.snapshots.map { ($0.id, $0) })
        var result: [ProjectSnapshot] = []
        var currentID = branch.headSnapshotID
        var visited = Set<UUID>()
        while let id = currentID, let snapshot = map[id], !visited.contains(id) {
            result.append(snapshot)
            visited.insert(id)
            currentID = snapshot.parentSnapshotID
        }
        return result
    }

    private func refreshSnapshots(for project: Project, selecting snapshot: ProjectSnapshot?) {
        snapshots = snapshotsForActiveBranch(in: project)
        if let snapshot {
            selectedSnapshot = snapshot
        }
    }
}
