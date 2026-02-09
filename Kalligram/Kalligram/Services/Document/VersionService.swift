import Foundation
import SwiftData
import AppKit
import SwiftUI

final class VersionService {
    static func createSnapshot(
        for document: Document,
        triggerType: String,
        modelContext: ModelContext
    ) -> Version {
        let attributed = attributedString(from: document)
        let formatted = DocumentFormattingService.applyingBodyStyle(to: attributed, document: document)
        let pageCount = estimatedPageCount(for: formatted, document: document)

        let version = Version(
            label: "\(triggerType.capitalized) — \(Date().formatted(date: .abbreviated, time: .shortened))",
            contentRTFData: document.contentRTFData,
            contentPlainText: document.contentPlainText,
            wordCount: document.wordCount,
            triggerType: triggerType,
            pageCount: pageCount
        )

        version.paperSize = document.paperSize
        version.marginTop = document.marginTop
        version.marginBottom = document.marginBottom
        version.marginLeft = document.marginLeft
        version.marginRight = document.marginRight
        version.lineSpacing = document.lineSpacing
        version.paragraphSpacingBefore = document.paragraphSpacingBefore
        version.paragraphSpacing = document.paragraphSpacing
        version.firstLineIndent = document.firstLineIndent
        version.bodyFontName = document.bodyFontName
        version.bodyFontSize = document.bodyFontSize
        version.bodyAlignment = document.bodyAlignment
        version.hyphenationEnabled = document.hyphenationEnabled
        version.includePageNumbers = document.includePageNumbers
        version.includeTableOfContents = document.includeTableOfContents

        version.previewImagePath = VersionPreviewService.savePreview(
            for: version,
            attributedString: formatted,
            document: document
        )

        version.document = document
        modelContext.insert(version)
        return version
    }

    static func restore(
        version: Version,
        to document: Document,
        modelContext: ModelContext
    ) {
        // Then restore
        document.contentRTFData = version.contentRTFData
        document.contentPlainText = version.contentPlainText
        document.paperSize = version.paperSize
        document.marginTop = version.marginTop
        document.marginBottom = version.marginBottom
        document.marginLeft = version.marginLeft
        document.marginRight = version.marginRight
        document.lineSpacing = version.lineSpacing
        document.paragraphSpacingBefore = version.paragraphSpacingBefore
        document.paragraphSpacing = version.paragraphSpacing
        document.firstLineIndent = version.firstLineIndent
        document.bodyFontName = version.bodyFontName
        document.bodyFontSize = version.bodyFontSize
        document.bodyAlignment = version.bodyAlignment
        document.hyphenationEnabled = version.hyphenationEnabled
        document.includePageNumbers = version.includePageNumbers
        document.includeTableOfContents = version.includeTableOfContents
        document.updatedAt = Date()

        NotificationCenter.default.post(name: .documentRestored, object: document.id)
    }

    static func branchToNewDocument(
        from version: Version,
        title: String,
        modelContext: ModelContext
    ) -> Document {
        let newDoc = Document(title: title, documentType: version.document?.documentTypeEnum ?? .article)
        newDoc.contentRTFData = version.contentRTFData
        newDoc.contentPlainText = version.contentPlainText
        newDoc.paperSize = version.paperSize
        newDoc.marginTop = version.marginTop
        newDoc.marginBottom = version.marginBottom
        newDoc.marginLeft = version.marginLeft
        newDoc.marginRight = version.marginRight
        newDoc.lineSpacing = version.lineSpacing
        newDoc.paragraphSpacingBefore = version.paragraphSpacingBefore
        newDoc.paragraphSpacing = version.paragraphSpacing
        newDoc.firstLineIndent = version.firstLineIndent
        newDoc.bodyFontName = version.bodyFontName
        newDoc.bodyFontSize = version.bodyFontSize
        newDoc.bodyAlignment = version.bodyAlignment
        newDoc.hyphenationEnabled = version.hyphenationEnabled
        newDoc.includePageNumbers = version.includePageNumbers
        newDoc.includeTableOfContents = version.includeTableOfContents
        if let project = version.document?.project {
            newDoc.project = project
        }
        modelContext.insert(newDoc)
        return newDoc
    }

    static func pruneVersions(
        for document: Document,
        keepLast count: Int = 50,
        modelContext: ModelContext
    ) {
        let sorted = document.versions.sorted { $0.createdAt > $1.createdAt }
        if sorted.count > count {
            for version in sorted.dropFirst(count) {
                if let path = version.previewImagePath, !path.isEmpty {
                    try? FileManager.default.removeItem(atPath: path)
                }
                modelContext.delete(version)
            }
        }
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
