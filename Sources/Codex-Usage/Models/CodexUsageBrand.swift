import AppKit

enum CodexUsageBrand {
    private static let resourceBundleName = "Codex-Usage_Codex-Usage.bundle"

    @MainActor
    static func menuBarImage(
        pointSize: NSSize = NSSize(width: 18, height: 18)
    ) -> NSImage? {
        guard let url = logoURL(), let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.size = pointSize
        image.isTemplate = true
        return image
    }

    private static func logoURL() -> URL? {
        if let resourceURL = Bundle.main.resourceURL,
           let appBundle = Bundle(
               url: resourceURL.appendingPathComponent(resourceBundleName)
           ),
           let url = appBundle.url(
               forResource: "CodexUsageLogo",
               withExtension: "png"
           ) {
            return url
        }

        return Bundle.module.url(
            forResource: "CodexUsageLogo",
            withExtension: "png"
        )
    }
}
