import AppKit

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
	static func coveredDisplays(
		windows: [WindowInfo],
		displays: [DisplayBounds],
		ownPID: pid_t
	) -> Set<CGDirectDisplayID> {
		var covered: Set<CGDirectDisplayID> = []

		for display in displays {
			let isCovered = windows.contains { window in
				window.pid != ownPID
					&& window.layer == 0
					&& window.bounds == display.bounds
			}

			if isCovered {
				covered.insert(display.id)
			}
		}

		return covered
	}
}
