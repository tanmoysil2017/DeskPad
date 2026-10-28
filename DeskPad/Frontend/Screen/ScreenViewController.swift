import Cocoa
import ReSwift

enum ScreenViewAction: Action {
    case setDisplayID(CGDirectDisplayID)
}

class ScreenViewController: SubscriberViewController<ScreenViewData>, NSWindowDelegate {
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(didClickOnScreen)))
    }

    private var display: CGVirtualDisplay!
    private var stream: CGDisplayStream?
    private var isWindowHighlighted = false
    private var previousResolution: CGSize?
    private var previousScaleFactor: CGFloat?
    private var requestedDesktopSize: CGSize?
    private var screenParametersObserver: NSObjectProtocol?

    deinit {
        if let observer = screenParametersObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.selectRequestedDisplayMode()
        }

        let descriptor = CGVirtualDisplayDescriptor()
        descriptor.setDispatchQueue(DispatchQueue.main)
        descriptor.name = "DeskPad Display"
        descriptor.maxPixelsWide = 5120
        descriptor.maxPixelsHigh = 5120
        descriptor.sizeInMillimeters = CGSize(width: 1600, height: 1000)
        descriptor.productID = 0x1234
        descriptor.vendorID = 0x3456
        descriptor.serialNum = 0x0001

        let display = CGVirtualDisplay(descriptor: descriptor)
        store.dispatch(ScreenViewAction.setDisplayID(display.displayID))
        self.display = display

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        let landscapeModes = [
            // 32:9
            CGVirtualDisplayMode(width: 5120, height: 1440, refreshRate: 60),
            // 21:9 (239:100, 12:5)
            CGVirtualDisplayMode(width: 5120, height: 2160, refreshRate: 60),
            CGVirtualDisplayMode(width: 3840, height: 1600, refreshRate: 60),
            CGVirtualDisplayMode(width: 3440, height: 1440, refreshRate: 60),
            // 16:9
            CGVirtualDisplayMode(width: 3840, height: 2160, refreshRate: 60),
            CGVirtualDisplayMode(width: 2560, height: 1440, refreshRate: 60),
            CGVirtualDisplayMode(width: 1920, height: 1080, refreshRate: 60),
            CGVirtualDisplayMode(width: 1600, height: 900, refreshRate: 60),
            CGVirtualDisplayMode(width: 1366, height: 768, refreshRate: 60),
            CGVirtualDisplayMode(width: 1280, height: 720, refreshRate: 60),
            // 16:10
            CGVirtualDisplayMode(width: 2560, height: 1600, refreshRate: 60),
            CGVirtualDisplayMode(width: 1920, height: 1200, refreshRate: 60),
            CGVirtualDisplayMode(width: 1680, height: 1050, refreshRate: 60),
            CGVirtualDisplayMode(width: 1440, height: 900, refreshRate: 60),
            CGVirtualDisplayMode(width: 1280, height: 800, refreshRate: 60),
        ]
        let savedWidth = UserDefaults.standard.integer(forKey: "desktopWidth")
        let savedHeight = UserDefaults.standard.integer(forKey: "desktopHeight")
        if (1 ... 5120).contains(savedWidth), (1 ... 5120).contains(savedHeight) {
            requestedDesktopSize = CGSize(width: savedWidth, height: savedHeight)
            settings.hiDPI = 0
            settings.modes = [
                CGVirtualDisplayMode(width: UInt(savedWidth), height: UInt(savedHeight), refreshRate: 60),
            ]
        } else {
            settings.modes = landscapeModes
        }
        display.apply(settings)
    }

    override func update(with viewData: ScreenViewData) {
        if viewData.isWindowHighlighted != isWindowHighlighted {
            isWindowHighlighted = viewData.isWindowHighlighted
            view.window?.backgroundColor = isWindowHighlighted
                ? NSColor(named: "TitleBarActive")
                : NSColor(named: "TitleBarInactive")
            if isWindowHighlighted {
                view.window?.orderFrontRegardless()
            }
        }

        if
            viewData.resolution != .zero,
            viewData.resolution != previousResolution
            || viewData.scaleFactor != previousScaleFactor
        {
            previousResolution = viewData.resolution
            previousScaleFactor = viewData.scaleFactor
            stream?.stop()
            stream = nil
            if let window = view.window {
                window.contentAspectRatio = viewData.resolution
                let aspectRatio = viewData.resolution.width / viewData.resolution.height
                window.contentMinSize = CGSize(
                    width: min(400, 300 * aspectRatio),
                    height: min(300, 400 / aspectRatio)
                )
                let currentScreen = window.screen
                let previewScreen = currentScreen?.displayID != display.displayID ? currentScreen : nil
                let hostScreen = previewScreen ?? NSScreen.screens.first {
                    $0.displayID != display.displayID
                        && CGDisplayMirrorsDisplay($0.displayID) != display.displayID
                }
                let visibleFrame = hostScreen?.visibleFrame ?? window.frame
                let availableSize = window.contentRect(forFrameRect: visibleFrame).size
                let scale = min(
                    1,
                    availableSize.width / viewData.resolution.width,
                    availableSize.height / viewData.resolution.height
                )
                window.setContentSize(CGSize(
                    width: viewData.resolution.width * scale,
                    height: viewData.resolution.height * scale
                ))
                window.setFrameOrigin(NSPoint(
                    x: visibleFrame.midX - window.frame.width / 2,
                    y: visibleFrame.midY - window.frame.height / 2
                ))
            }
            let stream = CGDisplayStream(
                dispatchQueueDisplay: display.displayID,
                outputWidth: Int(viewData.resolution.width * viewData.scaleFactor),
                outputHeight: Int(viewData.resolution.height * viewData.scaleFactor),
                pixelFormat: 1_111_970_369,
                properties: [
                    CGDisplayStream.showCursor: true,
                ] as CFDictionary,
                queue: .main,
                handler: { [weak self] _, _, frameSurface, _ in
                    if let surface = frameSurface {
                        self?.view.layer?.contents = surface
                    }
                }
            )
            self.stream = stream
            stream?.start()
        }
    }

    /// Reconfigure the virtual monitor itself, rather than selecting a synthesized rotated mode.
    @objc func rotateDisplay() {
        guard let currentMode = CGDisplayCopyDisplayMode(display.displayID) else {
            return
        }
        configureDesktop(width: currentMode.height, height: currentMode.width)
    }

    @objc func setDisplayResolution(_ sender: NSMenuItem) {
        guard let size = (sender.representedObject as? NSValue)?.sizeValue else {
            return
        }
        configureDesktop(width: Int(size.width), height: Int(size.height))
    }

    private func configureDesktop(width: Int, height: Int) {
        guard CGDisplayMirrorsDisplay(display.displayID) == kCGNullDirectDisplay else {
            showDisplayConfigurationError(
                "DeskPad is currently mirroring another monitor. In System Settings → Displays, first set DeskPad Display to Extended display. Choose the DeskPad resolution here, then set DELL to mirror DeskPad Display and optimize for DeskPad Display."
            )
            return
        }
        let settings = CGVirtualDisplaySettings()
        // Explicit 1× modes make the selected dimensions usable desktop space, not a Retina backing size.
        settings.hiDPI = 0
        settings.modes = [
            CGVirtualDisplayMode(width: UInt(width), height: UInt(height), refreshRate: 60),
        ]
        requestedDesktopSize = CGSize(width: width, height: height)
        guard display.apply(settings) else {
            requestedDesktopSize = nil
            showDisplayConfigurationError("macOS could not apply this resolution to DeskPad Display.")
            return
        }
    }

    private func selectRequestedDisplayMode() {
        guard
            let size = requestedDesktopSize,
            let modes = CGDisplayCopyAllDisplayModes(display.displayID, nil) as? [CGDisplayMode],
            let mode = modes.first(where: {
                $0.width == Int(size.width) && $0.height == Int(size.height)
                    && $0.pixelWidth == Int(size.width) && $0.pixelHeight == Int(size.height)
                    && $0.isUsableForDesktopGUI()
            })
        else {
            return
        }
        requestedDesktopSize = nil
        guard CGDisplaySetDisplayMode(display.displayID, mode, nil) == .success else {
            showDisplayConfigurationError("macOS rejected the selected resolution. If DELL is mirroring DeskPad, set Optimize for to DeskPad Display in System Settings → Displays.")
            return
        }
        UserDefaults.standard.set(Int(size.width), forKey: "desktopWidth")
        UserDefaults.standard.set(Int(size.height), forKey: "desktopHeight")
    }

    private func showDisplayConfigurationError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to configure DeskPad Display"
        alert.informativeText = message
        if let window = view.window {
            alert.beginSheetModal(for: window)
        }
    }

    func windowWillResize(_ window: NSWindow, to frameSize: NSSize) -> NSSize {
        let snappingOffset: CGFloat = 30
        let contentSize = window.contentRect(forFrameRect: NSRect(origin: .zero, size: frameSize)).size
        guard
            let screenResolution = previousResolution,
            abs(contentSize.width - screenResolution.width) < snappingOffset
        else {
            return frameSize
        }
        return window.frameRect(forContentRect: NSRect(origin: .zero, size: screenResolution)).size
    }

    @objc private func didClickOnScreen(_ gestureRecognizer: NSGestureRecognizer) {
        guard let screenResolution = previousResolution else {
            return
        }
        let clickedPoint = gestureRecognizer.location(in: view)
        let onScreenPoint = NSPoint(
            x: clickedPoint.x / view.frame.width * screenResolution.width,
            y: (view.frame.height - clickedPoint.y) / view.frame.height * screenResolution.height
        )
        store.dispatch(MouseLocationAction.requestMove(toPoint: onScreenPoint))
    }
}
