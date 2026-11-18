import Foundation
import UIKit
import Capacitor
import HealthKit
import WatchConnectivity
import CoreBluetooth

/// Liefert den Live-Puls an das Spiel (JS: `Capacitor.Plugins.FittPulse`).
/// Quellen: FITTGAME-Watch-App (WatchConnectivity), Bluetooth-Brustgurt (Heart Rate Service 0x180D)
/// und als Rückfall neue Herzfrequenz-Werte aus Apple Health.
@objc(FittPulsePlugin)
public class FittPulsePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "FittPulsePlugin"
    public let jsName = "FittPulse"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "info", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "state", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "haptic", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "bleConnect", returnType: CAPPluginReturnPromise)
    ]

    private let store = HKHealthStore()
    private var hrQuery: HKAnchoredObjectQuery?
    private var central: CBCentralManager?
    private var strap: CBPeripheral?
    private var wantsScan = false
    private let hrService = CBUUID(string: "180D")
    private let hrMeasurement = CBUUID(string: "2A37")

    override public func load() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - JS-Methoden

    @objc func info(_ call: CAPPluginCall) {
        call.resolve(watchInfo())
    }

    /// Kursstart: Health-Freigabe holen, Watch-App mit einem Workout öffnen, Health-Abfrage starten.
    @objc func start(_ call: CAPPluginCall) {
        let name = call.getString("name") ?? "FITTGAME"
        guard HKHealthStore.isHealthDataAvailable() else { call.resolve(watchInfo()); return }
        let hr = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        store.requestAuthorization(toShare: [], read: [hr]) { [weak self] _, _ in
            guard let self = self else { return }
            self.startHealthQuery()
            if WCSession.isSupported(), WCSession.default.activationState == .activated, WCSession.default.isWatchAppInstalled {
                let cfg = HKWorkoutConfiguration()
                cfg.activityType = .highIntensityIntervalTraining
                cfg.locationType = .indoor
                self.store.startWatchApp(with: cfg) { _, _ in
                    self.send(["cmd": "start", "name": name])
                }
            }
            call.resolve(self.watchInfo())
        }
    }

    /// Kursende: Watch beendet das Workout und speichert es in Health (oder verwirft es).
    @objc func stop(_ call: CAPPluginCall) {
        stopHealthQuery()
        var msg: [String: Any] = ["cmd": "stop", "discard": call.getBool("discard") ?? false]
        if let name = call.getString("name") { msg["name"] = name }
        if let energy = call.getInt("energy") { msg["energy"] = energy }
        if let kcal = call.getInt("kcal") { msg["kcal"] = kcal }
        send(msg, guaranteed: true)
        call.resolve()
    }

    /// Spielstand fürs Handgelenk: Track, Restzeit, Energie, Zielzone.
    @objc func state(_ call: CAPPluginCall) {
        var msg: [String: Any] = ["cmd": "state"]
        if let v = call.getString("track") { msg["track"] = v }
        for key in ["idx", "total", "energy", "left", "lo", "hi"] {
            if let v = call.getInt(key) { msg[key] = v }
        }
        msg["inZone"] = call.getBool("inZone") ?? false
        send(msg)
        call.resolve()
    }

    @objc func haptic(_ call: CAPPluginCall) {
        let type = call.getString("type") ?? "medium"
        DispatchQueue.main.async {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = type == "heavy" ? .heavy : type == "light" ? .light : .medium
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        call.resolve()
    }

    /// Sucht einen Bluetooth-Pulsgurt und verbindet den ersten gefundenen.
    @objc func bleConnect(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.wantsScan = true
            if self.central == nil {
                self.central = CBCentralManager(delegate: self, queue: nil)
            } else {
                self.scanIfReady()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                if self.strap == nil { self.central?.stopScan(); self.wantsScan = false }
            }
            call.resolve()
        }
    }

    // MARK: - Intern

    private func watchInfo() -> [String: Any] {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            return ["paired": false, "installed": false, "reachable": false]
        }
        let s = WCSession.default
        return ["paired": s.isPaired, "installed": s.isWatchAppInstalled, "reachable": s.isReachable]
    }

    private func send(_ msg: [String: Any], guaranteed: Bool = false) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        let s = WCSession.default
        if s.isReachable {
            s.sendMessage(msg, replyHandler: nil) { _ in
                if guaranteed { s.transferUserInfo(msg) }
            }
        } else if guaranteed {
            s.transferUserInfo(msg)
        }
    }

    private func emitHeartRate(_ bpm: Double, source: String) {
        guard bpm > 30, bpm < 240 else { return }
        notifyListeners("heartRate", data: ["bpm": bpm, "source": source])
    }

    private func startHealthQuery() {
        stopHealthQuery()
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let unit = HKUnit.count().unitDivided(by: .minute())
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, _, _ in
            guard let last = (samples as? [HKQuantitySample])?.last else { return }
            self?.emitHeartRate(last.quantity.doubleValue(for: unit), source: "health")
        }
        let query = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: handler)
        query.updateHandler = handler
        hrQuery = query
        store.execute(query)
    }

    private func stopHealthQuery() {
        if let q = hrQuery { store.stop(q) }
        hrQuery = nil
    }

    private func scanIfReady() {
        guard wantsScan, let central = central, central.state == .poweredOn else { return }
        central.scanForPeripherals(withServices: [hrService], options: nil)
    }
}

// MARK: - Apple Watch

extension FittPulsePlugin: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        notifyListeners("watch", data: watchInfo())
    }
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    public func sessionReachabilityDidChange(_ session: WCSession) {
        notifyListeners("watch", data: watchInfo())
    }
    public func sessionWatchStateDidChange(_ session: WCSession) {
        notifyListeners("watch", data: watchInfo())
    }
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let hr = message["hr"] as? Double { emitHeartRate(hr, source: "watch") }
    }
}

// MARK: - Bluetooth-Brustgurt

extension FittPulsePlugin: CBCentralManagerDelegate, CBPeripheralDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanIfReady()
    }
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard strap == nil else { return }
        strap = peripheral
        peripheral.delegate = self
        central.stopScan()
        central.connect(peripheral, options: nil)
    }
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        wantsScan = false
        peripheral.discoverServices([hrService])
        notifyListeners("ble", data: ["connected": true, "name": peripheral.name ?? "Brustgurt"])
    }
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        strap = nil
        notifyListeners("ble", data: ["connected": false])
    }
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        strap = nil
        notifyListeners("ble", data: ["connected": false])
    }
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == hrService {
            peripheral.discoverCharacteristics([hrMeasurement], for: service)
        }
    }
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for ch in service.characteristics ?? [] where ch.uuid == hrMeasurement {
            peripheral.setNotifyValue(true, for: ch)
        }
    }
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == hrMeasurement, let data = characteristic.value, data.count >= 2 else { return }
        // Byte 0 = Flags; Bit 0 gesetzt → Puls als 16-Bit-Wert, sonst 8 Bit
        let bpm: Int
        if data[0] & 0x01 == 0 {
            bpm = Int(data[1])
        } else if data.count >= 3 {
            bpm = Int(data[1]) | (Int(data[2]) << 8)
        } else {
            return
        }
        emitHeartRate(Double(bpm), source: "ble")
    }
}
