// ================================================================
//  KURSE: jede Einheit besteht aus Tracks (Spiel + Dauer + Ziel-Pulszone)
// ================================================================
// t(spiel, sekunden, [zoneVon, zoneBis], name, coach-ansage)
const t = (game, dur, zone, name, cue) => ({ game, dur, zone, name, cue });

export const COURSES = [
  {
    id: 'quick', name: 'Quick Burn', tag: 'Kurz & knackig', focus: 'Ganzkörper', intensity: 2, rest: 10,
    grad: ['#ffd500', '#ff8a1e'], icon: 'zap',
    desc: 'Die schnelle Runde für zwischendurch: einmal alles, einmal außer Atem.',
    tracks: [
      t('jacks', 45, [2, 3], 'Warm-up', 'Locker einspringen.'),
      t('punch', 70, [3, 4], 'Fäuste hoch', 'Triff die Ziele mit der richtigen Hand.'),
      t('sprint', 40, [4, 5], 'Sprint', 'Knie hoch, so schnell du kannst!'),
      t('smash', 75, [3, 4], 'Smash Party', 'Wischen, kicken, Bomben ausweichen.'),
      t('squat', 40, [3, 4], 'Squat Power', 'Tief runter, explosiv hoch.'),
      t('kick', 55, [3, 4], 'Kick-Finale', 'Letzter Track, gib alles!'),
      t('pose', 40, [1, 2], 'Cool-down', 'Ruhig atmen und Posen halten.')
    ]
  },
  {
    id: 'combat', name: 'Combat Blast', tag: 'Boxen & Kicken', focus: 'Kampf-Cardio', intensity: 3, rest: 12,
    grad: ['#ff2e4d', '#8b5cff'], icon: 'hand',
    desc: 'Schlag- und Kick-Kombinationen in neun Tracks mit zwei Puls-Gipfeln.',
    tracks: [
      t('pose', 50, [1, 2], 'Mobilisieren', 'Wir wärmen uns auf.'),
      t('punch', 85, [2, 3], 'Jab & Cross', 'Saubere Treffer, Rhythmus finden.'),
      t('kick', 70, [3, 4], 'Side Kicks', 'Hüfte eindrehen, kraftvoll kicken.'),
      t('smash', 90, [3, 4], 'Smash Party', 'Alles weg, was auf dich zukommt.'),
      t('wall', 70, [3, 3], 'Ausweichen', 'Bleib beweglich: ducken und springen.'),
      t('punch', 85, [4, 5], 'Power Round', 'Erster Gipfel: volle Kraft!'),
      t('sprint', 40, [4, 5], 'Fußarbeit', 'Schnelle Füße, Knie hoch!'),
      t('kick', 70, [4, 5], 'Kick-Gipfel', 'Zweiter Gipfel: nicht nachlassen!'),
      t('pose', 50, [1, 2], 'Cool-down', 'Puls runterbringen.')
    ]
  },
  {
    id: 'cardio', name: 'Cardio Attack', tag: 'Springen & Sprinten', focus: 'Ausdauer', intensity: 3, rest: 12,
    grad: ['#1de9b6', '#1ea7ff'], icon: 'star',
    desc: 'Sprünge, Sprints und Ausweichen: der Kurs für den großen Kalorienzähler.',
    tracks: [
      t('jacks', 55, [2, 3], 'Warm-up', 'Locker loslegen.'),
      t('sprint', 50, [3, 4], 'Lauf an', 'Finde dein Tempo.'),
      t('wall', 85, [3, 4], 'Hindernisse', 'Ducken, springen, zur Seite.'),
      t('squat', 50, [3, 4], 'Beine', 'Squats im Takt.'),
      t('smash', 90, [3, 4], 'Smash Party', 'Kurz Spaß, Puls bleibt oben.'),
      t('sprint', 50, [4, 5], 'Sprint-Gipfel', 'Jetzt zählt jede Sekunde!'),
      t('jacks', 55, [4, 5], 'Star Jumps', 'Arme ganz nach oben!'),
      t('kick', 70, [3, 4], 'Kicks', 'Sauber weiterkicken.'),
      t('sprint', 35, [4, 5], 'Endspurt', 'Alles raus!'),
      t('pose', 50, [1, 2], 'Cool-down', 'Stark gemacht. Runterkommen.')
    ]
  },
  {
    id: 'hiit', name: 'HIIT Storm', tag: '40 s Vollgas, kurze Pause', focus: 'Intervalle', intensity: 3, rest: 20,
    grad: ['#ff8a1e', '#ff2e4d'], icon: 'bomb',
    desc: 'Acht harte Intervalle. Ziel: in jeder Runde in die rote Zone, in der Pause erholen.',
    tracks: [
      t('jacks', 50, [2, 3], 'Warm-up', 'Gleich wird es ernst.'),
      t('sprint', 40, [4, 5], 'Runde 1', 'Vollgas!'),
      t('squat', 40, [4, 5], 'Runde 2', 'Tief und schnell!'),
      t('jacks', 40, [4, 5], 'Runde 3', 'Springen, springen, springen!'),
      t('punch', 40, [4, 5], 'Runde 4', 'Schnelle Hände!'),
      t('sprint', 40, [4, 5], 'Runde 5', 'Halbzeit, weiter!'),
      t('smash', 40, [4, 5], 'Runde 6', 'Alles wegfegen!'),
      t('squat', 40, [4, 5], 'Runde 7', 'Beine brennen? Gut so!'),
      t('sprint', 40, [4, 5], 'Runde 8', 'Letzte Runde, alles geben!'),
      t('pose', 50, [1, 2], 'Cool-down', 'Geschafft. Atmen.')
    ]
  },
  {
    id: 'flow', name: 'Flow & Reset', tag: 'Ruhig & kontrolliert', focus: 'Mobility', intensity: 1, rest: 8,
    grad: ['#8b5cff', '#1ea7ff'], icon: 'pose',
    desc: 'Posen, Balance und langsame Squats für Ruhetage oder nach dem Training.',
    tracks: [
      t('pose', 90, [1, 2], 'Ankommen', 'Ruhig bewegen, sauber halten.'),
      t('squat', 45, [2, 3], 'Langsame Squats', 'Kontrolliert runter und hoch.'),
      t('wall', 60, [2, 3], 'Beweglich bleiben', 'Locker ausweichen.'),
      t('pose', 90, [1, 2], 'Balance', 'Atmung beruhigen.')
    ]
  }
];

export const courseSecs = c => c.tracks.reduce((s, x) => s + x.dur, 0) + (c.tracks.length - 1) * c.rest;
export const courseMins = c => Math.round(courseSecs(c) / 60);
