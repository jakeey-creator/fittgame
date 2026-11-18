import Foundation
import HealthKit
import WatchConnectivity
import WatchKit

/// Startet ein Workout (damit die Watch den Puls im Sekundentakt misst), sendet Puls und Kalorien
/// ans iPhone und zeigt den Spielstand an, den das iPhone zurückschickt.
final class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var running = false
    @Published var heartRate: Double = 0
    @Published var kcal: Double = 0
    @Published var startDate: Date?

    // Spielstand vom iPhone
    @Published var courseName = "FITTGAME"
    @Published var track = ""
    @Published var idx = 0
    @Published var total = 0
    @Published var energy = 0
    @Published var left = 0
    @Published var lo = 0
    @Published var hi = 0
    @Published var inZone = false

    func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func authorize(_ done: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { done(false); return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        store.requestAuthorization(toShare: share, read: read) { ok, _ in done(ok) }
    }

    func start(configuration: HKWorkoutConfiguration? = nil) {
        guard session == nil else { return }
        let cfg = configuration ?? {
            let c = HKWorkoutConfiguration()
            c.activityType = .highIntensityIntervalTraining
            c.locationType = .indoor
            return c
        }()
        authorize { [weak self] ok in
            guard let self = self, ok else { return }
            DispatchQueue.main.async { self.begin(cfg) }
        }
    }

    private func begin(_ cfg: HKWorkoutConfiguration) {
        guard session == nil else { return }
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: cfg)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: cfg)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let now = Date()
            s.startActivity(with: now)
            b.beginCollection(withStart: now) { _, _ in }
            running = true
            startDate = now
            heartRate = 0
            kcal = 0
            WKInterfaceDevice.current().play(.start)
        } catch {
            session = nil
            builder = nil
        }
    }

    /// Beendet das Workout und speichert es in Health (oder verwirft es bei abgebrochenen Läufen).
    func stop(discard: Bool = false) {
        guard let s = session, let b = builder else { return }
        session = nil
        builder = nil
        let end = Date()
        s.end()
        b.endCollection(withEnd: end) { _, _ in
            if discard {
                b.discardWorkout()
            } else {
                b.finishWorkout { _, _ in }
            }
        }
        DispatchQueue.main.async {
            self.running = false
            self.track = ""
            self.inZone = false
            WKInterfaceDevice.current().play(.stop)
        }
    }

    private func apply(_ msg: [String: Any]) {
        switch msg["cmd"] as? String {
        case "start":
            if let name = msg["name"] as? String { courseName = name }
            energy = 0
            track = ""
            start()
        case "stop":
            if let e = msg["energy"] as? Int { energy = e }
            stop(discard: msg["discard"] as? Bool ?? false)
        case "state":
            let wasInZone = inZone, oldTrack = track
            track = msg["track"] as? String ?? track
            idx = msg["idx"] as? Int ?? idx
            total = msg["total"] as? Int ?? total
            energy = msg["energy"] as? Int ?? energy
            left = msg["left"] as? Int ?? left
            lo = msg["lo"] as? Int ?? lo
            hi = msg["hi"] as? Int ?? hi
            inZone = msg["inZone"] as? Bool ?? false
            if !oldTrack.isEmpty, oldTrack != track {
                WKInterfaceDevice.current().play(.notification)     // neuer Track
            } else if inZone, !wasInZone {
                WKInterfaceDevice.current().play(.success)          // Zielzone erreicht
            }
        default:
            break
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        var bpm: Double?
        var energyKcal: Double?
        for type in collectedTypes {
            guard let q = type as? HKQuantityType, let stats = workoutBuilder.statistics(for: q) else { continue }
            if q == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                bpm = stats.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            } else if q == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                energyKcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie())
            }
        }
        DispatchQueue.main.async {
            if let bpm = bpm { self.heartRate = bpm }
            if let e = energyKcal { self.kcal = e }
        }
        if let bpm = bpm, WCSession.default.activationState == .activated, WCSession.default.isReachable {
            WCSession.default.sendMessage(["hr": bpm, "kcal": energyKcal ?? 0], replyHandler: nil, errorHandler: nil)
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.session = nil
            self.builder = nil
            self.running = false
        }
    }
}

extension WorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.apply(message) }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async { self.apply(userInfo) }
    }
}
