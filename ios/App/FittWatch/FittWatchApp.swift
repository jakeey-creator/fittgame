import SwiftUI
import HealthKit
import WatchKit

/// FITTGAME auf der Apple Watch: misst den Puls während eines Kurses und schickt ihn live ans iPhone.
final class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WorkoutManager.shared.activateSession()
    }

    /// Wird aufgerufen, wenn das iPhone beim Kursstart die Watch-App öffnet.
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WorkoutManager.shared.start(configuration: workoutConfiguration)
    }
}

@main
struct FittWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var manager = WorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(manager)
        }
    }
}
