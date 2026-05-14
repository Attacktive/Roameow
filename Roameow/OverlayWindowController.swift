import AppKit

class OverlayWindowController: NSWindowController {
	private var petViewController: PetViewController?

	convenience init() {
		let screen = NSScreen.main ?? NSScreen.screens[0]
		let window = NSWindow(
			contentRect: screen.frame,
			styleMask: .borderless,
			backing: .buffered,
			defer: false
		)

		window.backgroundColor = .clear
		window.isOpaque = false
		window.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
		window.collectionBehavior = [.canJoinAllSpaces, .stationary]
		window.ignoresMouseEvents = true
		window.isReleasedWhenClosed = false

		self.init(window: window)

		let petVC = PetViewController()
		petViewController = petVC
		window.contentViewController = petVC
	}

	func handleScreenChange() {
		guard let screen = NSScreen.main else { return }
		window?.setFrame(screen.frame, display: true)
		petViewController?.clampToScreenBounds()
	}
}
