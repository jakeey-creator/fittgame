// ================================================================
//  FORTSCHRITT: XP, Level, Serie (Streak), Wochenpunkte, Verlauf
// ================================================================
const read = (k, d) => { try { const v = localStorage.getItem('fittgame.' + k); return v == null ? d : JSON.parse(v); } catch { return d; } };
const write = (k, v) => { try { localStorage.setItem('fittgame.' + k, JSON.stringify(v)); } catch {} };

export const RANKS = ['Rookie', 'Mover', 'Fighter', 'Athlet', 'Maschine', 'Beast', 'Legende'];
const day = (d = new Date()) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

// Level n beginnt bei 60 × (n−1)² XP
export function levelInfo(xp){
  const level = Math.floor(Math.sqrt(xp / 60)) + 1;
  const lo = 60 * (level - 1) ** 2, hi = 60 * level ** 2;
  return { level, lo, hi, pct: (xp - lo) / (hi - lo), rank: RANKS[Math.min(RANKS.length - 1, Math.floor((level - 1) / 3))] };
}

export const Progress = {
  data: Object.assign({ xp: 0, streak: 0, lastDay: '', best: {} }, read('progress', {})),
  history: read('history', []),
  get level(){ return levelInfo(this.data.xp); },
  // aktuelle Serie; verfällt, wenn gestern und heute nichts trainiert wurde
  get streak(){
    const y = new Date(); y.setDate(y.getDate() - 1);
    return this.data.lastDay === day() || this.data.lastDay === day(y) ? this.data.streak : 0;
  },
  get week(){
    const since = Date.now() - 7 * 864e5;
    const w = this.history.filter(h => h.date >= since);
    return { points: w.reduce((s, h) => s + (h.pulse?.points || 0), 0), kcal: w.reduce((s, h) => s + (h.pulse?.kcal || 0), 0),
      mins: Math.round(w.reduce((s, h) => s + h.secs, 0) / 60), count: w.length };
  },
  best(id){ return this.data.best[id] || 0; },
  // Einheit speichern; gibt XP-Gewinn, Level-Aufstieg und Rekord zurück
  add(entry){
    const before = this.level, prevBest = this.best(entry.id);
    const xp = Math.round(entry.energy + (entry.pulse?.points || 0) * 2);
    const today = day();
    if (this.data.lastDay !== today){ this.data.streak = this.streak + 1; this.data.lastDay = today; }
    this.data.xp += xp;
    const isBest = entry.energy > prevBest;
    if (isBest) this.data.best[entry.id] = entry.energy;
    entry.xp = xp; entry.date = Date.now();
    this.history.unshift(entry); this.history.length = Math.min(this.history.length, 60);
    write('progress', this.data); write('history', this.history);
    return { xp, before, after: this.level, levelUp: this.level.level > before.level, isBest, prevBest };
  },
  reset(){ this.data = { xp: 0, streak: 0, lastDay: '', best: {} }; this.history = []; write('progress', this.data); write('history', this.history); }
};
