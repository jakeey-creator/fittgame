# FITTGAME

Body-Tracking-Fitnessspiele im Browser: Die Kamera erkennt deinen Körper (MediaPipe Pose, läuft komplett auf dem Gerät), und du spielst 5 Bewegungsspiele von 1 bis 1,5 Minuten.

| Spiel | Dauer | Bewegung |
|---|---|---|
| 🥊 Box Rush | 1:00 | Neon-Ziele mit den Händen treffen |
| 🧱 Wall Dodge | 1:15 | Ducken, springen, links/rechts ausweichen |
| ⭐ Star Jumps | 1:00 | Hampelmänner zählen |
| 🏃 Knee Sprint | 1:00 | High Knees auf der Stelle |
| 🕺 Pose Match | 1:30 | Posen nachmachen und halten |

Alle Sounds und die Musik werden live mit der Web Audio API erzeugt, es gibt keine Audiodateien.

## Auf dem iPhone testen

Kamera im Browser geht nur über **https**. Der einfachste Weg:

1. GitHub → Repo → **Settings → Pages** → Source: *Deploy from a branch*, Branch wählen, Ordner `/ (root)` → Save.
2. Nach ca. 1 Min. die Seite `https://<user>.github.io/fittgame/` in **Safari** öffnen.
3. Kamera erlauben. Optional: Teilen → *Zum Home-Bildschirm*.
4. Handy hochkant hinstellen, 2–3 m zurückgehen, ganzer Körper im Bild.

Alternative ohne GitHub Pages: `index.html` per Drag & Drop auf <https://app.netlify.com/drop> ziehen.

Lokal am Rechner: `python3 -m http.server` → <http://localhost:8000> (localhost darf die Kamera ohne https nutzen).

## Später: iOS-App

Der Plan: dieselbe Spiellogik, aber Tracking mit Apples **Vision** (`VNDetectHumanBodyPoseRequest`) oder MediaPipe iOS, UI in SwiftUI/SpriteKit. Alternativ kann diese Web-Version schnell per Capacitor/WKWebView als App verpackt werden.
