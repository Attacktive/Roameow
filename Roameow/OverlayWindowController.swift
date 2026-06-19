import AppKit

class OverlayWindowController: NSWindowController {
	private var petViewController: PetViewController?

	convenience init(screen: NSScreen) {
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

		let petVC = PetViewController(screen: screen)
		petViewController = petVC
		window.contentViewController = petVC
	}

	func handleScreenChange(screen: NSScreen) {
		guard let window else { return }

		window.setFrame(screen.frame, display: true)
		petViewController?.clampToScreenBounds()
	}

	func show() {
		window?.orderFrontRegardless()
	}

	func setActive(_ active: Bool) {
		if active {
			show()
			petViewController?.resume()
			petViewController?.clampToScreenBounds()
		} else {
			window?.orderOut(nil)
			petViewController?.pause()
		}
	}
}
