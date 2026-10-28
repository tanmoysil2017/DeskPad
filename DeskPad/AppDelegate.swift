import Cocoa
import ReSwift

enum AppDelegateAction: Action {
    case didFinishLaunching
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        let viewController = ScreenViewController()
        window = NSWindow(contentViewController: viewController)
        window.delegate = viewController
        window.title = "DeskPad"
        window.makeKeyAndOrderFront(nil)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.backgroundColor = .white
        window.contentMinSize = CGSize(width: 400, height: 300)
        window.contentMaxSize = CGSize(width: 5120, height: 5120)
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenNone)

        let mainMenu = NSMenu()
        let mainMenuItem = NSMenuItem()
        let subMenu = NSMenu(title: "MainMenu")
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApp.terminate),
            keyEquivalent: "q"
        )
        subMenu.addItem(quitMenuItem)
        mainMenuItem.submenu = subMenu
        let displayMenuItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
        let displayMenu = NSMenu(title: "Display")
        let rotateMenuItem = NSMenuItem(
            title: "Rotate 90°",
            action: #selector(ScreenViewController.rotateDisplay),
            keyEquivalent: "r"
        )
        rotateMenuItem.target = viewController
        displayMenu.addItem(rotateMenuItem)
        displayMenu.addItem(.separator())
        let resolutions = [
            CGSize(width: 1080, height: 1920),
            CGSize(width: 1200, height: 1920),
            CGSize(width: 1500, height: 2400),
            CGSize(width: 1440, height: 2560),
            CGSize(width: 1600, height: 2560),
            CGSize(width: 1800, height: 2880),
            CGSize(width: 2100, height: 3360),
            CGSize(width: 2160, height: 3840),
            CGSize(width: 2400, height: 3840),
            CGSize(width: 2700, height: 4320),
            CGSize(width: 3000, height: 4800),
            CGSize(width: 2880, height: 5120),
            CGSize(width: 3200, height: 5120),
        ]
        for isPortrait in [true, false] {
            let title = isPortrait ? "Portrait Resolution" : "Landscape Resolution"
            let resolutionMenuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let resolutionMenu = NSMenu(title: title)
            for resolution in resolutions {
                let size = isPortrait ? resolution : CGSize(width: resolution.height, height: resolution.width)
                let matchesDell = resolution.width * 8 == resolution.height * 5
                let aspectRatio: String
                if isPortrait {
                    aspectRatio = matchesDell ? "5:8 — DELL" : "9:16"
                } else {
                    aspectRatio = matchesDell ? "8:5" : "16:9"
                }
                let item = NSMenuItem(
                    title: "\(Int(size.width)) × \(Int(size.height)) (\(aspectRatio))",
                    action: #selector(ScreenViewController.setDisplayResolution(_:)),
                    keyEquivalent: ""
                )
                item.target = viewController
                item.representedObject = NSValue(size: size)
                resolutionMenu.addItem(item)
            }
            resolutionMenuItem.submenu = resolutionMenu
            displayMenu.addItem(resolutionMenuItem)
        }
        displayMenuItem.submenu = displayMenu
        mainMenu.items = [mainMenuItem, displayMenuItem]
        NSApplication.shared.mainMenu = mainMenu

        store.dispatch(AppDelegateAction.didFinishLaunching)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
