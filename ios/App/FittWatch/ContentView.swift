import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var m: WorkoutManager

    var body: some View {
        if m.running {
            TabView {
                LiveView()
                ControlView()
            }
            .tabViewStyle(.page)
        } else {
            IdleView()
        }
    }
}

/// Startbildschirm, solange kein Kurs läuft.
private struct IdleView: View {
    @EnvironmentObject private var m: WorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.yellow)
            Text("FITTGAME")
                .font(.system(.title3, design: .rounded).weight(.heavy))
            Text("Starte einen Kurs auf dem iPhone. Die Pulsmessung beginnt dann automatisch.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Puls jetzt messen") { m.start() }
                .tint(.yellow)
        }
        .padding(.horizontal, 6)
    }
}

/// Live-Anzeige während des Kurses: Puls, Zielzone, Track, Energie.
private struct LiveView: View {
    @EnvironmentObject private var m: WorkoutManager
    @State private var beat = false

    private var bpm: Int { Int(m.heartRate.rounded()) }
    private var zoneColor: Color {
        guard m.hi > 0, bpm > 0 else { return .red }
        if bpm < m.lo { return .blue }
        if bpm > m.hi { return .red }
        return .yellow
    }
    private var hint: String {
        guard m.hi > 0, bpm > 0 else { return "Puls wird gemessen" }
        if bpm < m.lo { return "Puls hoch!" }
        if bpm > m.hi { return "Etwas rausnehmen" }
        return "In der Zone · Punkte ×2"
    }

    var body: some View {
        VStack(spacing: 2) {
            if !m.track.isEmpty {
                Text(m.total > 1 ? "\(m.idx)/\(m.total) · \(m.track)" : m.track)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                Text(m.courseName)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(zoneColor)
                    .scaleEffect(beat ? 1.2 : 0.95)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: beat)
                Text(bpm > 0 ? "\(bpm)" : "--")
                    .font(.system(size: 58, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(zoneColor)
            }
            Text(hint)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(zoneColor)
            if m.hi > 0 {
                Text("Ziel \(m.lo)–\(m.hi) bpm")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("\(m.energy)", systemImage: "bolt.fill").foregroundStyle(.yellow)
                Spacer()
                Label("\(Int(m.kcal))", systemImage: "flame.fill").foregroundStyle(.orange)
                Spacer()
                Text(m.left > 0 ? "\(m.left)s" : "")
                    .monospacedDigit()
            }
            .font(.system(.footnote, design: .rounded).weight(.bold))
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
        .onAppear { beat = true }
    }
}

/// Zweite Seite: Workout von der Watch aus beenden.
private struct ControlView: View {
    @EnvironmentObject private var m: WorkoutManager

    var body: some View {
        VStack(spacing: 10) {
            if let start = m.startDate {
                Text(start, style: .timer)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .monospacedDigit()
            }
            Button(role: .destructive) { m.stop() } label: {
                Label("Beenden", systemImage: "xmark")
            }
        }
    }
}
