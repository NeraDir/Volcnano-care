

import SwiftUI
import AppsFlyerLib

@main
struct OneSixFiveSAdnasdnaskndApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
        AppsFlyerLib.shared().appsFlyerDevKey = fehgrg
        AppsFlyerLib.shared().appleAppID = appIdVova
        AppsFlyerLib.shared().isDebug = false
        
    }

    var body: some Scene {
        WindowGroup {
            Ogiurwhgjehgr()
        }
    }
}
