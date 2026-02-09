import SwiftData
import Foundation

@Model
final class ProjectSnapshot {
    var id: UUID
    var label: String
    var createdAt: Date
    var triggerType: String
    var wordCount: Int
    var pageCount: Int
    var previewImagePath: String?
    var parentSnapshotID: UUID?

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \SnapshotDocument.snapshot)
    var documents: [SnapshotDocument]

    init(
        label: String,
        triggerType: String,
        wordCount: Int,
        pageCount: Int,
        project: Project?,
        parentSnapshotID: UUID? = nil
    ) {
        self.id = UUID()
        self.label = label
        self.createdAt = Date()
        self.triggerType = triggerType
        self.wordCount = wordCount
        self.pageCount = pageCount
        self.project = project
        self.parentSnapshotID = parentSnapshotID
        self.documents = []
    }
}
