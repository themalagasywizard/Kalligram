import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SwiftData

struct FileCommands: Commands {
    let appViewModel: AppViewModel
    let appState: AppState
    let modelContext: ModelContext

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open...") {
                openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Close Tab") {
                guard let doc = appViewModel.selectedDocument else { return }
                appViewModel.closeDocument(doc, allDocuments: fetchAllDocuments(), in: appState)
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Show Next Tab") {
                appViewModel.selectNextOpenDocument(allDocuments: fetchAllDocuments(), in: appState)
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button("Show Previous Tab") {
                appViewModel.selectPreviousOpenDocument(allDocuments: fetchAllDocuments(), in: appState)
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
        }

        CommandGroup(after: .saveItem) {
            Button("Save as PDF...") {
                exportSelectedDocument(format: .pdf)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Save as Word...") {
                exportSelectedDocument(format: .docx)
            }

            Divider()

            Button("Export...") {
                appState.isExportSheetPresented = true
            }
        }
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = DocumentImportService.supportedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if url.hasDirectoryPath {
                importProject(from: url)
            } else {
                importFile(from: url, project: nil)
            }
        }
    }

    private func importProject(from url: URL) {
        let project = Project(name: url.lastPathComponent)
        modelContext.insert(project)

        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        for fileURL in contents where !fileURL.hasDirectoryPath {
            if DocumentImportService.isSupportedFileURL(fileURL) {
                importFile(from: fileURL, project: project)
            }
        }

        try? modelContext.save()
    }

    private func fetchAllDocuments() -> [Document] {
        let descriptor = FetchDescriptor<Document>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func importFile(from url: URL, project: Project?) {
        do {
            let result = try DocumentImportService.importFile(from: url)
            let document = appViewModel.createDocument(
                title: result.originalFileName,
                type: .article,
                project: project,
                in: modelContext
            )
            document.contentRTFData = result.attributedString.toRTFData()
            document.contentPlainText = result.attributedString.string
            document.updatedAt = Date()
            document.sourceFilePath = result.sourceFilePath
            document.sourceFileType = result.sourceFileType
            document.importedAt = Date()
            if let project {
                document.project = project
            }
            try? modelContext.save()

            // Open the imported document in the tab bar
            appViewModel.openDocument(document, in: appState)
        } catch {
            NSSound.beep()
        }
    }

    private func exportSelectedDocument(format: ExportFormat) {
        guard let document = appViewModel.selectedDocument else { return }
        let attributed = attributedString(from: document)
        let metadata = ExportMetadata(
            title: document.title,
            author: "Author",
            paperSize: document.paperSizeEnum,
            margins: NSEdgeInsets(
                top: document.marginTop,
                left: document.marginLeft,
                bottom: document.marginBottom,
                right: document.marginRight
            ),
            lineSpacing: document.lineSpacing,
            includePageNumbers: true,
            includeTableOfContents: false
        )

        let exportVM = ExportViewModel()
        exportVM.selectedFormat = format
        exportVM.filename = document.title

        Task { @MainActor in
            if let data = await exportVM.export(attributedString: attributed, metadata: metadata) {
                exportVM.saveToFile(data: data)
            }
        }
    }

    private func attributedString(from document: Document) -> NSAttributedString {
        if let rtfData = document.contentRTFData,
           let attr = NSAttributedString.fromRTFData(rtfData) {
            return attr
        }
        return NSAttributedString(string: document.contentPlainText)
    }
}
