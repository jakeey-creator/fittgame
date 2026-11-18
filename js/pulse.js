// ================================================================
//  PULS: Profil, Herzfrequenz-Zonen, Quellen (Apple Watch / Bluetooth / Schätzung), Aufzeichnung
// ================================================================
const read = (k, d) => { try { const v = localStorage.getItem('fittgame.' + k); return v == null ? d : JSON.parse(v); } catch { return d; } };
const write = (k, v) => { try { localStorage.setItem('fittgame.' + k, JSON.stringify(v)); } catch {} };
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

export const ZONES = [
  { n: 1, name: 'Locker',   lo: 0.50, col: '#8e9aaf' },
  { n: 2, name: 'Fatburn',  lo: 0.60, col: '#1ea7ff' },
  { n: 3, name: 'Cardio',   lo: 0.70, col: '#1de9b6' },
  { n: 4, name: 'Power',    lo: 0.80, col: '#ff8a1e' },
  { n: 5, name: 'Maximum',  lo: 0.90, col: '#ff2e4d' }
];
export const zoneCol = z => z >= 1 ? ZONES[Math.min(z, 5) - 1].col : '#6b6b76';

export const profile = Object.assign({ name: '', age: 30, weight: 75, sex: 'm', rest: 65, maxHr: 0, coach: true, setup: false }, read('profile', {}));
export function saveProfile(patch){ Object.assign(profile, patch); write('profile', profile); }

// Maximalpuls: eigener Wert oder Tanaka-Formel (208 − 0,7 × Alter)
export const maxHr = () => profile.maxHr > 100 ? profile.maxHr : Math.round(208 - 0.7 * profile.age);
export function zoneOf(bpm){
  const p = bpm / maxHr();
  let z = 0; for (const Z of ZONES) if (p >= Z.lo) z = Z.n;
  return z;
}
export function zoneRange(z){
  const m = maxHr(), lo = ZONES[z - 1].lo, hi = z < 5 ? ZONES[z].lo : 1;
  return [Math.round(lo * m), Math.round(hi * m)];
}
// Kalorien pro Minute aus dem Puls (Keytel et al. 2005), nach unten durch den Ruheumsatz begrenzt
export function kcalPerMin(bpm){
  const { age, weight, sex } = profile;
  const k = sex === 'f'
    ? (-20.4022 + 0.4472 * bpm - 0.1263 * weight + 0.074 * age) / 4.184
    : (-55.0969 + 0.6309 * bpm + 0.1988 * weight + 0.2017 * age) / 4.184;
  return Math.max(weight * 1.1 / 60, k);
}

const native = () => window.Capacitor?.isNativePlatform?.() ? window.Capacitor.Plugins?.FittPulse : null;

export const Pulse = {
  bpm: 0, source: 'none',            // 'watch' | 'ble' | 'health' | 'estimate' | 'none'
  est: 0, lastReal: 0, bleName: '', watch: { paired: false, installed: false, reachable: false },
  onChange: null,
  get real(){ return this.source === 'watch' || this.source === 'ble' || this.source === 'health'; },
  get hasNative(){ return !!native(); },
  get canBLE(){ return !!native() || !!navigator.bluetooth; },

  init(){
    this.est = profile.rest;
    const n = native(); if (!n) return;
    n.addListener('heartRate', e => this.sample(e.bpm, e.source));
    n.addListener('watch', e => { Object.assign(this.watch, e); this.onChange?.(); });
    n.addListener('ble', e => { this.bleName = e.connected ? (e.name || 'Brustgurt') : ''; this.onChange?.(); });
    n.info().then(i => { Object.assign(this.watch, i); this.onChange?.(); }).catch(() => {});
  },
  // echter Messwert von Watch, Brustgurt oder Health
  sample(bpm, source){
    if (!(bpm > 30 && bpm < 240)) return;
    const rank = { watch: 3, ble: 3, health: 1 };
    if (this.real && rank[source] < rank[this.source] && performance.now() - this.lastReal < 8000) return;
    this.bpm = Math.round(bpm); this.source = source; this.lastReal = performance.now(); this.est = bpm;
  },
  // Schätzung aus der Bewegungsintensität (0..1), falls kein Sensor liefert
  feedMotion(intensity, dt){
    const target = profile.rest + (maxHr() * 0.93 - profile.rest) * Math.pow(clamp(intensity, 0, 1), 0.75);
    const tau = target > this.est ? 22 : 40;
    this.est += (target - this.est) * Math.min(1, dt / tau);
    if (!this.real || performance.now() - this.lastReal > 10000){ this.bpm = Math.round(this.est); this.source = 'estimate'; }
  },
  idle(){ if (!this.real || performance.now() - this.lastReal > 10000){ this.source = 'none'; this.bpm = 0; this.est = profile.rest; } },

  async connectBLE(){
    const n = native();
    if (n){ await n.bleConnect(); return; }
    if (!navigator.bluetooth) throw new Error('Bluetooth wird von diesem Browser nicht unterstützt');
    const dev = await navigator.bluetooth.requestDevice({ filters: [{ services: ['heart_rate'] }] });
    const srv = await (await dev.gatt.connect()).getPrimaryService('heart_rate');
    const ch = await srv.getCharacteristic('heart_rate_measurement');
    ch.addEventListener('characteristicvaluechanged', e => {
      const v = e.target.value, bpm = v.getUint8(0) & 1 ? v.getUint16(1, true) : v.getUint8(1);
      this.sample(bpm, 'ble');
    });
    await ch.startNotifications();
    this.bleName = dev.name || 'Brustgurt';
    dev.addEventListener('gattserverdisconnected', () => { this.bleName = ''; this.onChange?.(); });
    this.onChange?.();
  },
  // Workout auf der Watch starten/stoppen und Spielstand ans Handgelenk schicken (nur in der App)
  start(name){ return native()?.start({ name }).then(i => { Object.assign(this.watch, i); this.onChange?.(); }).catch(() => {}); },
  stop(summary){ return native()?.stop(summary).catch(() => {}); },
  state(s){ native()?.state(s).catch(() => {}); },
  haptic(type = 'medium'){ native()?.haptic({ type }).catch(() => {}); }
};

// Zeichnet eine Trainingseinheit sekundengenau auf
export class PulseSession {
  constructor(){ this.samples = []; this.zoneSecs = [0, 0, 0, 0, 0, 0]; this.points = 0; this.kcal = 0; this.max = 0; this.sum = 0; this.n = 0;
    this.acc = 0; this.inTarget = 0; this.estimated = 0; this.marks = []; }
  mark(label){ this.marks.push({ i: this.samples.length, label }); }
  tick(dt, bpm, source, target){
    this.acc += dt;
    while (this.acc >= 1){
      this.acc -= 1;
      if (!bpm) continue;
      const z = zoneOf(bpm);
      this.samples.push(bpm); this.zoneSecs[z]++; this.points += z / 12;      // Zone 3 = 15 Punkte pro Minute
      this.kcal += kcalPerMin(bpm) / 60; this.max = Math.max(this.max, bpm); this.sum += bpm; this.n++;
      if (target && z >= target[0] && z <= target[1]) this.inTarget++;
      if (source === 'estimate') this.estimated++;
    }
  }
  summary(){
    const step = Math.max(1, Math.ceil(this.samples.length / 240));
    return {
      avg: this.n ? Math.round(this.sum / this.n) : 0, max: this.max, kcal: Math.round(this.kcal), points: Math.round(this.points),
      zoneSecs: this.zoneSecs.slice(), secs: this.n, inTarget: this.n ? this.inTarget / this.n : 0,
      estimated: this.n ? this.estimated / this.n > 0.5 : true,
      samples: this.samples.filter((_, i) => i % step === 0), step,
      marks: this.marks.map(m => ({ i: Math.floor(m.i / step), label: m.label }))
    };
  }
}
