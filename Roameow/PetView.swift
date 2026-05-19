import AppKit
import AVFoundation

class PetView: NSView {
	private let imageView = NSImageView()
	private var audioPlayer: AVAudioPlayer?
	private var movementTimer: Timer?
	private var targetPosition: CGPoint = .zero
	private var lastTickTime: TimeInterval = 0
	private var isIdle = false
	private var isSetUp = false

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

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(prefsChanged),
			name: UserDefaults.didChangeNotification,
			object: nil
		)
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		guard window != nil, !isSetUp else { return }
		isSetUp = true

		let size = CGFloat(prefs.petSize)

		imageView.frame = CGRect(
			x: (bounds.width - size) / 2,
			y: (bounds.height - size) / 2,
			width: size,
			height: size
		)

		pickNewTarget()
		startTimer()
	}

	// MARK: - Image & Audio

	private func loadPetImage() {
		let customPath = prefs.customImagePath
		if !customPath.isEmpty, let image = NSImage(contentsOf: URL(fileURLWithPath: customPath)) {
			imageView.image = image
		} else if let url = Bundle.main.url(forResource: "Happy Cat", withExtension: "gif") {
			imageView.image = NSImage(contentsOf: url)
		}

		let size = CGFloat(prefs.petSize)
		imageView.frame.size = CGSize(width: size, height: size)
	}

	private func loadAudio() {
		let url: URL?
		let customPath = prefs.customSoundPath
		if !customPath.isEmpty {
			url = URL(fileURLWithPath: customPath)
		} else {
			url = Bundle.main.url(forResource: "meow", withExtension: "mp3")
		}

		guard let url else { return }

		audioPlayer = try? AVAudioPlayer(contentsOf: url)
		audioPlayer?.volume = Float(prefs.volume)
		audioPlayer?.prepareToPlay()
	}

	// MARK: - Movement

	private func startTimer() {
		movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
			self?.tick()
		}

		RunLoop.main.add(movementTimer!, forMode: .common)
	}

	func pause() {
		movementTimer?.invalidate()
		movementTimer = nil
	}

	func resume() {
		guard isSetUp, movementTimer == nil else { return }
		startTimer()
	}

	private func updateMousePassthrough() {
		guard let window else { return }

		let mouseScreen = NSEvent.mouseLocation
		let petScreen = window.convertToScreen(imageView.frame)

		window.ignoresMouseEvents = !petScreen.contains(mouseScreen)
	}

	private func tick() {
		updateMousePassthrough()
		guard prefs.movementEnabled, !isIdle else { return }

		let now = ProcessInfo.processInfo.systemUptime
		let speed = prefs.speed
		let frameTime = lastTickTime == 0 ? 1.0 / 60.0 : now - lastTickTime
		let normalizedSpeed = speed * (frameTime / (1.0 / 60.0))
		lastTickTime = now

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
		guard maxX > 0, maxY > 0 else { return }

		targetPosition = CGPoint(
			x: CGFloat.random(in: 0...maxX),
			y: CGFloat.random(in: 0...maxY)
		)
	}

	func clampToScreenBounds() {
		var origin = imageView.frame.origin
		let size = imageView.frame.size
		origin.x = max(0, min(origin.x, bounds.width - size.width))
		origin.y = max(0, min(origin.y, bounds.height - size.height))

		imageView.frame.origin = origin
		pickNewTarget()
	}

	// MARK: - Click

	override func mouseDown(with event: NSEvent) {
		audioPlayer?.stop()
		audioPlayer?.currentTime = 0
		audioPlayer?.play()
	}

	// MARK: - Preferences

	@objc private func prefsChanged() {
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			let size = CGFloat(self.prefs.petSize)
			self.imageView.frame.size = CGSize(width: size, height: size)
			self.loadPetImage()
			self.loadAudio()
			self.clampToScreenBounds()
		}
	}

	deinit {
		movementTimer?.invalidate()
		NotificationCenter.default.removeObserver(self)
	}
}
