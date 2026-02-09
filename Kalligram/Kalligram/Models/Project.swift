import SwiftData
import Foundation

@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var createdAt: Date
    var updatedAt: Date
    var colorTag: String?
    var sortOrder: Int
    var activeBranchID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \Document.project)
    var documents: [Document]

    @Relationship(deleteRule: .cascade, inverse: \ProjectBranch.project)
    var branches: [ProjectBranch]

    @Relationship(deleteRule: .cascade, inverse: \ProjectSnapshot.project)
    var snapshots: [ProjectSnapshot]

    init(name: String, projectDescription: String = "") {
        self.id = UUID()
        self.name = name
        self.projectDescription = projectDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = 0
        self.activeBranchID = nil
        self.documents = []
        self.branches = []
        self.snapshots = []
    }
}
