import AppKit
import CoreText
import Foundation

enum ProjectSnapshotPreviewService {
    static func savePreview(
        for snapshot: ProjectSnapshot,
        attributedString: NSAttributedString,
        document: Document
    ) -> String? {
        guard let image = renderPreview(from: attributedString, document: document) else { return nil }
        let url = previewURL(for: snapshot.id)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if let data = pngData(from: image) {
                try data.write(to: url, options: .atomic)
                return url.path
            }
        } catch {
            return nil
        }
        return nil
    }

    static func previewImage(from path: String?) -> NSImage? {
        guard let path, !path.isEmpty else { return nil }
        return NSImage(contentsOfFile: path)
    }

    static func previewURL(for snapshotID: UUID) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("Kalligram", isDirectory: true)
            .appendingPathComponent("ProjectSnapshots", isDirectory: true)
            .appendingPathComponent(snapshotID.uuidString, isDirectory: true)
            .appendingPathComponent("preview.png")
    }

    private static func renderPreview(
        from attributedString: NSAttributedString,
        document: Document
    ) -> NSImage? {
        let size = NSSize(
            width: document.paperSizeEnum.widthPoints,
            height: document.paperSizeEnum.heightPoints
        )
        let contentRect = CGRect(
            x: document.marginLeft,
            y: document.marginTop,
            width: max(0, size.width - document.marginLeft - document.marginRight),
            height: max(0, size.height - document.marginTop - document.marginBottom)
        )

        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
        let path = CGPath(rect: contentRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(frame, context)

        context.restoreGState()
        image.unlockFocus()

        return image
    }

    private static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
