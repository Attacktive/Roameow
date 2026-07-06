import AppKit
import AVFoundation
import Combine

class PetView: NSView {
	private let imageView = NSImageView()
	private var audioPlayer: AVAudioPlayer?
	private let displayLinkDriver = DisplayLinkDriver()
	private var targetPosition: CGPoint = .zero
	private var lastFrameTimestamp: TimeInterval = 0
	private var isIdle = false
	private var isSetUp = false
	private var lastImageURL: URL?
	private var lastSoundURL: URL?
	private var cancellable: AnyCancellable?

	private let prefs = Preferences.shared

	override init(frame: NSRect) {
		super.init(frame: frame)
		setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}

	private func setup() {
		wantsLayer = true
		imageView.animates = true
		imageView.imageScaling = .scaleProportionallyUpOrDown
		addSubview(imageView)

		loadPetImage()
		loadAudio()

		cancellable = prefs.objectWillChange
			.receive(on: DispatchQueue.main)
			.sink { [weak self] in self?.applyPreferences() }
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		guard
			window != nil,
			!isSetUp
		else {
			return
		}

		isSetUp = true

		let size = CGFloat(prefs.petSize)

		imageView.frame = CGRect(
			x: (bounds.width - size) / 2,
			y: (bounds.height - size) / 2,
			width: size,
			height: size
		)

		/*
		Pilot light: a tiny, effectively invisible dot pinned inside the menu-bar strip.
		The macOS 26 compositor silently drops the surface binding of a window whose visible output is entirely transparent — exactly what happens here whenever the pet walks fully behind an app window, since the rest of the overlay is clear.
		Once dropped, every commit is ignored (the pet stays invisible even back on open desktop) until a window-server-level event such as Mission Control rebinds the surface; no notification fires and no app-side kick rebinds it reliably.
		Prevention is therefore the only sound fix: keep at least one visible pixel composited at all times. Normal windows cannot cover the menu-bar strip, so the dot's contribution never reaches zero there.
		Do not remove this as decoration — it IS the fix for the pet staying invisible after de-occlusion.
		*/
		let pilotLight = NSView(frame: NSRect(x: 2, y: bounds.height - 4, width: 2, height: 2))
		pilotLight.identifier = NSUserInterfaceItemIdentifier("pilotLight")
		pilotLight.wantsLayer = true
		pilotLight.layer?.backgroundColor = NSColor.white.cgColor
		pilotLight.alphaValue = 0.05
		pilotLight.autoresizingMask = [.minYMargin, .maxXMargin]
		addSubview(pilotLight)

		pickNewTarget()
		startDisplayLink()
	}

	// MARK: - Image & Audio

	private func loadPetImage() {
		let url = prefs.resolvedImageURL
		lastImageURL = url
		imageView.image = url.flatMap { NSImage(contentsOf: $0) }
	}

	private func loadAudio() {
		let url = prefs.resolvedSoundURL
		lastSoundURL = url
		guard let url else {
			audioPlayer = nil
			return
		}

		audioPlayer = try? AVAudioPlayer(contentsOf: url)
		audioPlayer?.volume = Float(prefs.volume)
		audioPlayer?.prepareToPlay()
	}

	// MARK: - Movement

	private func startDisplayLink() {
		displayLinkDriver.onFrame = { [weak self] timestamp in
			self?.tick(timestamp: timestamp)
		}

		displayLinkDriver.start(for: self)
	}

	func pause() {
		displayLinkDriver.stop()
		lastFrameTimestamp = 0
	}

	func resume() {
		guard
			isSetUp,
			!displayLinkDriver.isRunning
		else {
			return
		}

		startDisplayLink()
	}

	private func updateMousePassthrough() {
		guard let window else { return }

		let mouseScreen = NSEvent.mouseLocation
		let petScreen = window.convertToScreen(imageView.frame)

		window.ignoresMouseEvents = !petScreen.contains(mouseScreen)
	}

	private func tick(timestamp: TimeInterval) {
		updateMousePassthrough()
		guard
			prefs.movementEnabled,
			!isIdle
		else {
			// Drop the stale timestamp so the first frame after idle/disabled movement starts fresh instead of integrating the whole gap in one step.
			lastFrameTimestamp = 0
			return
		}

		let speed = prefs.speed
		let frameTime = lastFrameTimestamp == 0 ? 1.0 / 60.0 : timestamp - lastFrameTimestamp
		let normalizedSpeed = speed * (frameTime / (1.0 / 60.0))
		lastFrameTimestamp = timestamp

		var origin = imageView.frame.origin
		let dx = targetPosition.x - origin.x
		let dy = targetPosition.y - origin.y
		let distance = sqrt(dx * dx + dy * dy)

		if distance <= normalizedSpeed {
			imageView.frame.origin = targetPosition
			onArrival()
		} else {
			let ratio = normalizedSpeed / distance
			origin.x += dx * ratio
			origin.y += dy * ratio
			imageView.frame.origin = origin
		}
	}

	private func onArrival() {
		if prefs.idleEnabled, Double.random(in: 0...1) < prefs.idleProbability / 100.0 {
			isIdle = true
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
				self?.isIdle = false
				self?.pickNewTarget()
			}
		} else {
			pickNewTarget()
		}
	}

	private func pickNewTarget() {
		let size = imageView.frame.size
		let maxX = bounds.width - size.width
		let maxY = bounds.height - size.height
		guard
			maxX > 0,
			maxY > 0
		else {
			return
		}

		targetPosition = CGPoint(
			x: CGFloat.random(in: 0...maxX),
			y: CGFloat.random(in: 0...maxY)
		)
	}

	func clampToScreenBounds() {
		let size = imageView.frame.size
		let maxX = max(0, bounds.width - size.width)
		let maxY = max(0, bounds.height - size.height)

		imageView.frame.origin = CGPoint(
			x: min(max(0, imageView.frame.origin.x), maxX),
			y: min(max(0, imageView.frame.origin.y), maxY)
		)

		targetPosition = CGPoint(
			x: min(max(0, targetPosition.x), maxX),
			y: min(max(0, targetPosition.y), maxY)
		)
	}

	// MARK: - Click

	override func mouseDown(with event: NSEvent) {
		audioPlayer?.stop()
		audioPlayer?.currentTime = 0
		audioPlayer?.play()
	}

	// MARK: - Preferences

	private func applySize(_ size: CGFloat) {
		imageView.frame.size = CGSize(width: size, height: size)
		clampToScreenBounds()
	}

	private func applyPreferences() {
		let size = CGFloat(prefs.petSize)
		if imageView.frame.size.width != size {
			applySize(size)
		}

		if prefs.resolvedImageURL != lastImageURL {
			loadPetImage()
		}

		audioPlayer?.volume = Float(prefs.volume)

		if prefs.resolvedSoundURL != lastSoundURL {
			loadAudio()
		}
	}

	deinit {
		displayLinkDriver.stop()
	}
}
