import AppKit

extension NSScreen {
	var displayID: CGDirectDisplayID? {
		deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
	}
}

struct WindowInfo {
	let bounds: CGRect
	let pid: pid_t
	let layer: Int
}

struct DisplayBounds {
	let id: CGDirectDisplayID
	let bounds: CGRect
}

final class FullscreenDetector {
	static func coveredDisplays(windows: [WindowInfo],displays: [DisplayBounds],ownPID: pid_t) -> Set<CGDirectDisplayID> {
		var covered: Set<CGDirectDisplayID> = []

		for display in displays {
			let isCovered = windows.contains { window in
				window.pid != ownPID && window.layer == 0 && window.bounds == display.bounds
			}

			if isCovered {
				covered.insert(display.id)
			}
		}

		return covered
	}

	private let ownPID: pid_t = ProcessInfo.processInfo.processIdentifier
	private let onChange: (Set<CGDirectDisplayID>) -> Void
	private var lastCovered: Set<CGDirectDisplayID>?

	init(onChange: @escaping (Set<CGDirectDisplayID>) -> Void) {
		self.onChange = onChange
	}

	func start() {
		let center = NSWorkspace.shared.notificationCenter

		center.addObserver(
			self,
			selector: #selector(evaluate),
			name: NSWorkspace.activeSpaceDidChangeNotification,
			object: nil
		)

		center.addObserver(
			self,
			selector: #selector(evaluate),
			name: NSWorkspace.didActivateApplicationNotification,
			object: nil
		)

		evaluate()
	}

	@objc func evaluate() {
		let displays = Self.currentDisplays()
		let covered: Set<CGDirectDisplayID>

		if displays.count == 1 {
			let isFullscreen = NSApplication.shared.currentSystemPresentationOptions.contains(.fullScreen)
			covered = isFullscreen ? [displays[0].id] : []
		} else {
			let windows = Self.currentWindows()
			covered = Self.coveredDisplays(windows: windows, displays: displays, ownPID: ownPID)
		}

		guard covered != lastCovered else { return }

		lastCovered = covered
		onChange(covered)
	}

	private static func currentWindows() -> [WindowInfo] {
		let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
		guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
			return []
		}

		return infoList.compactMap { entry in
			guard
				let boundsDict = entry[kCGWindowBounds as String] as? NSDictionary,
				let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
				let pid = (entry[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
				let layer = (entry[kCGWindowLayer as String] as? NSNumber)?.intValue,
				layer == 0
			else {
				return nil
			}

			return WindowInfo(bounds: bounds, pid: pid, layer: layer)
		}
	}

	private static func currentDisplays() -> [DisplayBounds] {
		NSScreen.screens.compactMap { screen in
			guard let id = screen.displayID else { return nil }
			return DisplayBounds(id: id, bounds: CGDisplayBounds(id))
		}
	}

	deinit {
		NSWorkspace.shared.notificationCenter.removeObserver(self)
	}
}
