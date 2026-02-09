import SwiftData
import Foundation

@Model
final class ProjectBranch {
    var id: UUID
    var name: String
    var createdAt: Date
    var isDefault: Bool
    var headSnapshotID: UUID?

    var project: Project?

    init(name: String, project: Project?, isDefault: Bool = false, headSnapshotID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.isDefault = isDefault
        self.headSnapshotID = headSnapshotID
        self.project = project
    }
}
