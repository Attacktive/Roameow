import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
	convenience init() {
		let hostingView = NSHostingView(rootView: SettingsView())

		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 400, height: 360),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)

		window.title = "Roameow"
		window.contentView = hostingView
		window.center()
		window.isReleasedWhenClosed = false

		self.init(window: window)
	}
}
