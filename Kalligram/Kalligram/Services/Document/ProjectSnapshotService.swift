import Foundation
import SwiftData
import AppKit

enum ProjectSnapshotService {
    static func ensureProject(for document: Document, modelContext: ModelContext) -> Project {
        if let project = document.project {
            return project
        }
        if let existing = try? modelContext.fetch(
            FetchDescriptor<Project>(
                predicate: #Predicate { $0.name == "Personal Workspace" }
            )
        ).first {
            document.project = existing
            return existing
        }

        let project = Project(name: "Personal Workspace", projectDescription: "Auto-created for version control")
        modelContext.insert(project)
        document.project = project
        return project
    }

    static func ensureDefaultBranch(for project: Project, modelContext: ModelContext) -> ProjectBranch {
        if let activeID = project.activeBranchID,
           let active = project.branches.first(where: { $0.id == activeID }) {
            return active
        }

        if let existingDefault = project.branches.first(where: { $0.isDefault }) {
            project.activeBranchID = existingDefault.id
            return existingDefault
        }

        if let first = project.branches.first {
            project.activeBranchID = first.id
            return first
        }

        let branch = ProjectBranch(name: "Main", project: project, isDefault: true)
        modelContext.insert(branch)
        project.activeBranchID = branch.id
        return branch
    }

    static func createSnapshot(
        for project: Project,
        sourceDocument: Document?,
        triggerType: String,
        modelContext: ModelContext
    ) -> ProjectSnapshot {
        let branch = ensureDefaultBranch(for: project, modelContext: modelContext)
        let label = "\(triggerType.capitalized) — \(Date().formatted(date: .abbreviated, time: .shortened))"

        let totalWordCount = project.documents.reduce(0) { $0 + $1.wordCount }
        let totalPageCount = max(1, project.documents.reduce(0) { partial, doc in
            let attributed = attributedString(from: doc)
            let formatted = DocumentFormattingService.applyingBodyStyle(to: attributed, document: doc)
            return partial + estimatedPageCount(for: formatted, document: doc)
        })

        let snapshot = ProjectSnapshot(
            label: label,
            triggerType: triggerType,
            wordCount: totalWordCount,
            pageCount: totalPageCount,
            project: project,
            parentSnapshotID: branch.headSnapshotID
        )

        for doc in project.documents {
            let snapshotDoc = SnapshotDocument(document: doc)
            snapshotDoc.snapshot = snapshot
            modelContext.insert(snapshotDoc)
        }

        if let previewDoc = sourceDocument ?? project.documents.first {
            let attributed = attributedString(from: previewDoc)
            let formatted = DocumentFormattingService.applyingBodyStyle(to: attributed, document: previewDoc)
            snapshot.previewImagePath = ProjectSnapshotPreviewService.savePreview(
                for: snapshot,
                attributedString: formatted,
                document: previewDoc
            )
        }

        modelContext.insert(snapshot)

        branch.headSnapshotID = snapshot.id
        project.updatedAt = Date()
        return snapshot
    }

    static func restore(
        snapshot: ProjectSnapshot,
        to project: Project,
        modelContext: ModelContext
    ) {
        let snapshotDocs = snapshot.documents
        let snapshotMap = Dictionary(uniqueKeysWithValues: snapshotDocs.map { ($0.documentID, $0) })

        for doc in project.documents {
            if let snap = snapshotMap[doc.id] {
                apply(snapshot: snap, to: doc)
            }
        }

        for snap in snapshotDocs where !project.documents.contains(where: { $0.id == snap.documentID }) {
            let newDoc = Document(title: snap.title, documentType: snap.documentTypeEnum)
            newDoc.id = snap.documentID
            apply(snapshot: snap, to: newDoc)
            newDoc.project = project
            modelContext.insert(newDoc)
        }

        project.updatedAt = Date()

        for doc in project.documents {
            NotificationCenter.default.post(name: .documentRestored, object: doc.id)
        }
    }

    static func createBranch(
        from snapshot: ProjectSnapshot,
        name: String,
        project: Project,
        modelContext: ModelContext
    ) -> ProjectBranch {
        let branch = ProjectBranch(name: name, project: project, isDefault: false, headSnapshotID: snapshot.id)
        modelContext.insert(branch)
        project.activeBranchID = branch.id
        return branch
    }

    static func checkoutBranch(
        _ branch: ProjectBranch,
        in project: Project,
        modelContext: ModelContext
    ) -> ProjectSnapshot? {
        project.activeBranchID = branch.id
        guard let headID = branch.headSnapshotID,
              let snapshot = project.snapshots.first(where: { $0.id == headID }) else {
            return nil
        }
        restore(snapshot: snapshot, to: project, modelContext: modelContext)
        return snapshot
    }

    private static func apply(snapshot: SnapshotDocument, to document: Document) {
        document.title = snapshot.title
        document.documentType = snapshot.documentType
        document.contentRTFData = snapshot.contentRTFData
        document.contentPlainText = snapshot.contentPlainText
        document.paperSize = snapshot.paperSize
        document.marginTop = snapshot.marginTop
        document.marginBottom = snapshot.marginBottom
        document.marginLeft = snapshot.marginLeft
        document.marginRight = snapshot.marginRight
        document.lineSpacing = snapshot.lineSpacing
        document.paragraphSpacingBefore = snapshot.paragraphSpacingBefore
        document.paragraphSpacing = snapshot.paragraphSpacing
        document.firstLineIndent = snapshot.firstLineIndent
        document.bodyFontName = snapshot.bodyFontName
        document.bodyFontSize = snapshot.bodyFontSize
        document.bodyAlignment = snapshot.bodyAlignment
        document.hyphenationEnabled = snapshot.hyphenationEnabled
        document.includePageNumbers = snapshot.includePageNumbers
        document.includeTableOfContents = snapshot.includeTableOfContents
        document.updatedAt = Date()
    }

    private static func attributedString(from document: Document) -> NSAttributedString {
        if let rtfData = document.contentRTFData,
           let attr = NSAttributedString.fromRTFData(rtfData) {
            return attr
        }
        return NSAttributedString(string: document.contentPlainText)
    }

    private static func estimatedPageCount(
        for attributedString: NSAttributedString,
        document: Document
    ) -> Int {
        let margins = NSEdgeInsets(
            top: document.marginTop,
            left: document.marginLeft,
            bottom: document.marginBottom,
            right: document.marginRight
        )
        let paginator = PaginationViewModel()
        paginator.paginate(attributedString: attributedString, paperSize: document.paperSizeEnum, margins: margins)
        return max(1, paginator.pageCount)
    }
}
