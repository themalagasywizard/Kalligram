import SwiftData
import Foundation

@Model
final class SnapshotDocument {
    var id: UUID
    var documentID: UUID
    var title: String
    var documentType: String
    var contentRTFData: Data?
    var contentPlainText: String
    var wordCount: Int

    // Layout snapshot
    var paperSize: String = PaperSize.letter.rawValue
    var marginTop: Double = 72
    var marginBottom: Double = 72
    var marginLeft: Double = 72
    var marginRight: Double = 72
    var lineSpacing: Double = 1.5
    var paragraphSpacingBefore: Double = 0
    var paragraphSpacing: Double = 12
    var firstLineIndent: Double = 0
    var bodyFontName: String = "Georgia"
    var bodyFontSize: Double = 16
    var bodyAlignment: String = ParagraphAlignment.left.rawValue
    var hyphenationEnabled: Bool = false
    var includePageNumbers: Bool = true
    var includeTableOfContents: Bool = false

    var snapshot: ProjectSnapshot?

    init(document: Document) {
        self.id = UUID()
        self.documentID = document.id
        self.title = document.title
        self.documentType = document.documentType
        self.contentRTFData = document.contentRTFData
        self.contentPlainText = document.contentPlainText
        self.wordCount = document.wordCount

        self.paperSize = document.paperSize
        self.marginTop = document.marginTop
        self.marginBottom = document.marginBottom
        self.marginLeft = document.marginLeft
        self.marginRight = document.marginRight
        self.lineSpacing = document.lineSpacing
        self.paragraphSpacingBefore = document.paragraphSpacingBefore
        self.paragraphSpacing = document.paragraphSpacing
        self.firstLineIndent = document.firstLineIndent
        self.bodyFontName = document.bodyFontName
        self.bodyFontSize = document.bodyFontSize
        self.bodyAlignment = document.bodyAlignment
        self.hyphenationEnabled = document.hyphenationEnabled
        self.includePageNumbers = document.includePageNumbers
        self.includeTableOfContents = document.includeTableOfContents
    }

    var documentTypeEnum: DocumentType {
        get { DocumentType(rawValue: documentType) ?? .article }
        set { documentType = newValue.rawValue }
    }
}
