import AppKit
import Testing
@testable import Ghostty

@MainActor
@Suite(.serialized)
struct TerminalControllerRestorationTests {
    @Test(arguments: ["never", "default", "always"])
    func reloadUpdatesExistingWindow(initialSetting: String) throws {
        try withController(windowSaveState: initialSetting) { controller, reload in
            let window = try #require(controller.window)
            #expect(window.isRestorable == (initialSetting != "never"))
            if window.isRestorable {
                expectRestorationMetadata(window)
            }

            for setting in ["never", "default", "never", "always", "never"] {
                try reload(setting)

                #expect(controller.window === window)
                #expect(window.isRestorable == (setting != "never"))
                if window.isRestorable {
                    expectRestorationMetadata(window)
                }
            }
        }
    }

    @Test(arguments: ["never", "default", "always"])
    func reloadKeepsCustomCommandExcluded(initialSetting: String) throws {
        try withController(windowSaveState: initialSetting, command: "echo test") { controller, reload in
            let window = try #require(controller.window)
            let identifier = window.identifier
            #expect(!window.isRestorable)
            #expect(window.restorationClass == nil)

            for setting in ["never", "default", "always"] {
                try reload(setting)

                #expect(!window.isRestorable)
                #expect(window.restorationClass == nil)
                #expect(window.identifier == identifier)
            }
        }
    }

    @Test(arguments: ["never", "always"])
    func surfaceConfigDoesNotChangeRestoration(initialSetting: String) throws {
        try withController(windowSaveState: initialSetting) { controller, _ in
            let window = try #require(controller.window)
            let identifier = window.identifier
            let restorationClass = window.restorationClass
            let config = try TemporaryConfig(
                "window-save-state = \(initialSetting == "never" ? "always" : "never")"
            )
            postConfig(config, object: NSObject())

            #expect(window.isRestorable == (initialSetting != "never"))
            #expect(window.identifier == identifier)
            #expect(window.restorationClass == restorationClass)
        }
    }

    private func withController(
        windowSaveState: String,
        command: String? = nil,
        _ body: (TerminalController, (String) throws -> Void) throws -> Void
    ) throws {
        let originalConfig = try #require((NSApp.delegate as? AppDelegate)?.ghostty.config)
        let config = try TemporaryConfig("window-save-state = \(windowSaveState)")
        let ghostty = Ghostty.App(configPath: config.temporaryFile.path)
        try #require(ghostty.app != nil)
        var baseConfig = Ghostty.SurfaceConfiguration()
        baseConfig.command = command
        let controller = TerminalController(ghostty, withBaseConfig: baseConfig, withSurfaceTree: .init())
        defer {
            if controller.isWindowLoaded {
                controller.window?.close()
            }
            postConfig(originalConfig)
        }
        try body(controller, { setting in
            try "window-save-state = \(setting)".write(to: config.temporaryFile, atomically: true, encoding: .utf8)
            ghostty.reloadConfig()
        })
    }

    private func postConfig(_ config: Ghostty.Config, object: Any? = nil) {
        NotificationCenter.default.post(
            name: .ghosttyConfigDidChange,
            object: object,
            userInfo: [Notification.Name.GhosttyConfigChangeKey: config]
        )
    }

    private func expectRestorationMetadata(_ window: NSWindow) {
        #expect(window.restorationClass == TerminalWindowRestoration.self)
        #expect(window.identifier == .init(String(describing: TerminalWindowRestoration.self)))
    }
}
