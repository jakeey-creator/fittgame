# FITTGAME

Fitness als Spiel: Die Kamera erkennt deinen Körper, dein Puls steuert die Punkte. Du spielst Kurse aus mehreren
Tracks mit Ziel-Pulszonen (ähnlich einem Studio-Kurs, nur als Game) oder einzelne Quick Games.
Läuft als Web-App im Browser und als native iPhone-/iPad-App mit Apple-Watch-App.

## Was drin ist

**Puls als Spielmechanik**
- Profil (Alter, Gewicht, Ruhepuls) → fünf Pulszonen, Max-Puls nach Tanaka (208 − 0,7 × Alter) oder eigener Wert.
- Live-Puls im Spiel mit Zonenfarbe. Jeder Track hat eine Zielzone: Bist du drin, zählt jeder Treffer **doppelt**.
- Pulspunkte (mehr Punkte pro Minute in höheren Zonen), Kalorien aus dem Puls (Keytel-Formel), Pulskurve und Zeit pro Zone in der Auswertung.
- Coach-Stimme sagt Tracks an und reagiert auf deinen Puls („Puls hoch“, „in der Zone“, „kurz rausnehmen“).

**Pulsquellen** (automatisch die beste verfügbare)
| Quelle | Wo | Hinweis |
|---|---|---|
| Apple Watch (FITTGAME-Watch-App) | iPhone-App | startet mit dem Kurs automatisch ein Workout, sendet den Puls live, speichert das Training in Health |
| Bluetooth-Brustgurt (Polar, Wahoo, Garmin …) | iPhone-App, Chrome | Profil → Pulsmessung → Verbinden |
| Apple Health | iPhone-App | Rückfall, wenn auf der Watch ein anderes Workout läuft |
| Schätzung aus der Bewegung | überall | ohne Sensor; als „≈ geschätzt“ markiert, kein Messwert |

**Kurse** (`js/courses.js`)
| Kurs | Dauer | Inhalt |
|---|---|---|
| Quick Burn | ca. 7 min | 7 Tracks, einmal alles |
| Combat Blast | ca. 12 min | Boxen & Kicken, zwei Puls-Gipfel |
| Cardio Attack | ca. 12 min | Springen, Sprinten, Ausweichen |
| HIIT Storm | ca. 10 min | 8 × 40 s Vollgas, 20 s Pause |
| Flow & Reset | ca. 5 min | Posen, Balance, langsame Squats |

**Spiele** (als Tracks in Kursen und einzeln als Quick Game): Power Punch, Kick Attack, Smash Party, Wall Dodge,
Star Jumps, Knee Sprint, Squat Power, Pose Match.

**Fortschritt:** XP und Level, Tages-Serie, 7-Tage-Übersicht, Verlauf mit allen Einheiten. Alles bleibt auf dem Gerät.

## Im Browser testen

Kamera geht nur über **https**: <https://jakeey-creator.github.io/fittgame/> in Safari öffnen.
Lokal: `python3 -m http.server` → <http://localhost:8000>.
Zum schnellen Durchklicken: `?short` an die Adresse hängen, dann sind alle Tracks stark verkürzt.

## iPhone-, iPad- und Watch-App

**Du brauchst:** Mac mit Xcode 16+, Node.js 20+, Apple-ID. Für die Watch-App: Apple Watch mit watchOS 10+.

```bash
npm install
npm run ios          # baut www/, kopiert es ins Xcode-Projekt und öffnet Xcode
```

In Xcode:
1. Projekt **App** → Target **App** → *Signing & Capabilities* → dein *Team* wählen.
2. Dasselbe für das Target **FittWatch**.
3. Falls die Bundle-ID schon vergeben ist: Projekt **App** → *Build Settings* → ganz unten *User-Defined* →
   `FITT_BUNDLE_ID` ändern (z. B. `com.deinname.fittgame`). Die Watch-ID leitet sich automatisch daraus ab.
4. iPhone anschließen, als Ziel wählen, **▶ Run**. Die Watch-App wird mit installiert
   (sonst: Watch-App auf dem iPhone → *Verfügbare Apps* → FITTGAME installieren).
5. Beim ersten Kurs: Kamera und Health erlauben (am iPhone und an der Watch).

Mit kostenloser Apple-ID läuft die App 7 Tage, danach erneut aus Xcode starten.

**So arbeitet die Watch-Verbindung:** Beim Kursstart öffnet das iPhone die Watch-App (`startWatchApp`), die Watch
startet ein HIIT-Workout und schickt Puls und Kalorien per WatchConnectivity ans iPhone. Das iPhone schickt Track,
Restzeit, Energie und Zielzone zurück; die Watch zeigt das an und tippt dir ans Handgelenk, wenn du die Zone triffst.

### Aufbau

| Pfad | Inhalt |
|---|---|
| `index.html` | Oberfläche, Tracking (MediaPipe Pose), Spiele, Kurs-Ablauf, Sounds |
| `js/pulse.js` | Profil, Zonen, Pulsquellen, Aufzeichnung, Kalorien |
| `js/courses.js` | Kurse und Tracks |
| `js/progress.js` | XP, Level, Serie, Verlauf |
| `ios/App/App/FittPulsePlugin.swift` | Brücke Watch / Health / Bluetooth → Spiel |
| `ios/App/FittWatch/` | watchOS-App (SwiftUI, HealthKit-Workout) |
| `scripts/build-www.mjs` | baut `www/` mit lokalem MediaPipe, Modell und Schrift (App läuft offline) |
| `scripts/add-watch-target.rb` | hat Watch-Target und Plugin ins Xcode-Projekt eingetragen |

Jeder Push baut iPhone- und Watch-App per GitHub Actions auf einem Mac (`.github/workflows/ios.yml`).

## Hinweis

FITTGAME ist ein Fitnessspiel und kein Medizinprodukt. Puls- und Kalorienwerte sind Richtwerte.
