# FITTGAME

Body-Tracking-Fitnessspiele im Browser: Die Kamera erkennt deinen Körper (MediaPipe Pose, läuft komplett auf dem Gerät), und du spielst 5 Bewegungsspiele von 1 bis 1,5 Minuten.

| Spiel | Dauer | Bewegung |
|---|---|---|
| ✋ Power Punch | 1:15 | Runden: Hände (richtige Hand), Sandsack-Combos 1-2-3, Beide Hände |
| 🦶 Kick Attack | 1:00 | Runden: seitliche Kicks links/rechts, Knie hoch |
| 💥 Smash Party | 1:15 | Monster & Obst wegwischen, Bälle & Dosen wegkicken, Bomben nicht berühren (5 Wellen) |
| 🧱 Wall Dodge | 1:15 | Ducken, springen, links/rechts ausweichen |
| ⭐ Star Jumps | 1:00 | Hampelmänner, Hände zu den Zielen oben/unten |
| 🕺 Pose Match | 1:30 | Posen nachmachen und halten |

Look angelehnt an das Referenzvideo: natürliches Kamerabild, dezente Gelenk-Kreise, farbige Hand-/Fuß-Marker
(blau/rot = linke/rechte Hand, türkis/pink = linker/rechter Fuß), Ziele mit Blitz und gestrichelter Führungslinie,
Rundentitel („Sack 2 von 3“), Comic-Treffer („POW!“, „KICK!“, „PERFECT!“), ⚡ Energie + ×Combo und ein dunkler Ergebnis-Screen.

Alle Sounds und die Musik werden live mit der Web Audio API erzeugt, es gibt keine Audiodateien.

## Auf dem iPhone testen

Kamera im Browser geht nur über **https**. Der einfachste Weg:

1. GitHub → Repo → **Settings → Pages** → Source: *Deploy from a branch*, Branch wählen, Ordner `/ (root)` → Save.
2. Nach ca. 1 Min. die Seite `https://<user>.github.io/fittgame/` in **Safari** öffnen.
3. Kamera erlauben. Optional: Teilen → *Zum Home-Bildschirm*.
4. Handy hochkant hinstellen, 2–3 m zurückgehen, ganzer Körper im Bild.

Alternative ohne GitHub Pages: `index.html` per Drag & Drop auf <https://app.netlify.com/drop> ziehen.

Lokal am Rechner: `python3 -m http.server` → <http://localhost:8000> (localhost darf die Kamera ohne https nutzen).

## iPhone- & iPad-App (Capacitor)

Die App packt dieselbe `index.html` in eine native iOS-App (iPhone + iPad, ab iOS 15). MediaPipe, das Pose-Modell
(`assets/pose_landmarker_lite.task`) und die Schrift liegen im App-Bundle, die App läuft also komplett offline.
Native Extras: Kamera-Hinweistext, Ton auch bei Stumm-Schalter, Bildschirm bleibt während des Spiels an.

**Du brauchst:** einen Mac mit Xcode (kostenlos im App Store), Node.js 20+ und eine Apple-ID.

```bash
npm install
npm run ios          # baut www/, kopiert es ins Xcode-Projekt und öffnet Xcode
```

In Xcode:
1. Links das Projekt **App** → Target **App** → **Signing & Capabilities** → bei *Team* deine Apple-ID wählen
   (ggf. *Bundle Identifier* ändern, z.B. `com.deinname.fittgame`).
2. iPhone per Kabel anschließen, oben als Ziel auswählen, **▶ Run** drücken.
3. Beim ersten Mal am iPhone: *Einstellungen → Allgemein → VPN & Geräteverwaltung* → Entwickler vertrauen.

Mit kostenloser Apple-ID läuft die App 7 Tage, danach einfach erneut aus Xcode starten. Für TestFlight / App Store
brauchst du das Apple Developer Program (99 €/Jahr).

Nach Änderungen an `index.html`: `npm run sync` (oder `npm run ios`).

Jeder Push baut die App per GitHub Actions auf einem Mac (`.github/workflows/ios.yml`), damit Build-Fehler sofort auffallen.
