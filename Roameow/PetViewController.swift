import AppKit

class PetViewController: NSViewController {
	private var petView: PetView { view as! PetView }
	private let screen: NSScreen

	init(screen: NSScreen) {
		self.screen = screen
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		self.screen = NSScreen.main ?? NSScreen.screens[0]
		super.init(coder: coder)
	}

	override func loadView() {
		self.view = PetView(frame: NSRect(origin: .zero, size: screen.frame.size))
	}

	func clampToScreenBounds() { petView.clampToScreenBounds() }
	func pause() { petView.pause() }
	func resume() { petView.resume() }
}
