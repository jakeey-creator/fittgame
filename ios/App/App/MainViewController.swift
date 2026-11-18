import UIKit
import Capacitor

/// Haupt-WebView der App. Registriert das native Puls-Plugin (Apple Watch, Health, Bluetooth).
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(FittPulsePlugin())
    }
}
