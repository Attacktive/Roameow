import AppKit
import CoreVideo
import QuartzCore

/// Drives a per-frame callback in lockstep with a display's vsync.
///
/// macOS 14+ uses `CADisplayLink`, delivered on the main run loop and bound to the view's own display (so it tracks refresh rate across multi-monitor moves for free).
/// macOS 12–13 falls back to `CVDisplayLink`, whose handler runs on a dedicated thread and is hopped to the main queue before `onFrame` fires.
final class DisplayLinkDriver: NSObject {
	/// Called once per screen refresh with that frame's timestamp, in seconds.
	var onFrame: ((TimeInterval) -> Void)?

	// Stored untyped because the CADisplayLink class is only available on macOS 14+, above this app's 12.0 floor.
	private var caDisplayLink: AnyObject?
	private var cvDisplayLink: CVDisplayLink?

	var isRunning: Bool {
		caDisplayLink != nil || cvDisplayLink != nil
	}

	/// Starts driving frames for the display that `view` currently occupies.
	func start(for view: NSView) {
		stop()

		if #available(macOS 14.0, *) {
			let link = view.displayLink(target: self, selector: #selector(caDisplayLinkFired(_:)))
			link.add(to: .main, forMode: .common)
			caDisplayLink = link
		} else {
			startCVDisplayLink(for: view)
		}
	}

	func stop() {
		if #available(macOS 14.0, *) {
			(caDisplayLink as? CADisplayLink)?.invalidate()
		}

		caDisplayLink = nil

		if let cvDisplayLink {
			CVDisplayLinkStop(cvDisplayLink)
			self.cvDisplayLink = nil
		}
	}

	@available(macOS 14.0, *)
	@objc private func caDisplayLinkFired(_ link: CADisplayLink) {
		onFrame?(link.timestamp)
	}

	// MARK: - CVDisplayLink fallback (macOS 12–13)

	// CVDisplayLink is deprecated on macOS 15+, but it is the only vsync-synced clock available below the macOS 14 floor where NSView.displayLink exists.
	// The deprecation warnings are therefore expected and intentional.
	private func startCVDisplayLink(for view: NSView) {
		var link: CVDisplayLink?
		CVDisplayLinkCreateWithActiveCGDisplays(&link)
		guard let link else { return }

		if let displayID = view.window?.screen?.displayID {
			CVDisplayLinkSetCurrentCGDisplay(link, displayID)
		}

		// The handler runs on the link's own thread, so it hops to the main queue; capturing self weakly keeps the link from retaining the driver.
		CVDisplayLinkSetOutputHandler(link) { [weak self] _, _, inOutputTime, _, _ in
			let output = inOutputTime.pointee
			let timestamp = Double(output.videoTime) / Double(output.videoTimeScale)

			DispatchQueue.main.async {
				self?.onFrame?(timestamp)
			}

			return kCVReturnSuccess
		}

		CVDisplayLinkStart(link)
		cvDisplayLink = link
	}

	deinit {
		stop()
	}
}
