// scripts/generate_assets.js
// 合成 5 个 WAV 音效到 assets/sounds/
// 用法: node scripts/generate_assets.js

const fs = require('fs');
const path = require('path');

const OUT_DIR = path.resolve(__dirname, '..', 'assets', 'sounds');
fs.mkdirSync(OUT_DIR, { recursive: true });

const SAMPLE_RATE = 22050;
const BITS_PER_SAMPLE = 16;
const NUM_CHANNELS = 1;

function writeWav(filePath, samples) {
  const dataLen = samples.length * (BITS_PER_SAMPLE / 8);
  const buf = Buffer.alloc(44 + dataLen);
  buf.write('RIFF', 0);
  buf.writeUInt32LE(36 + dataLen, 4);
  buf.write('WAVE', 8);
  buf.write('fmt ', 12);
  buf.writeUInt32LE(16, 16);              // PCM chunk size
  buf.writeUInt16LE(1, 20);               // PCM format
  buf.writeUInt16LE(NUM_CHANNELS, 22);
  buf.writeUInt32LE(SAMPLE_RATE, 24);
  buf.writeUInt32LE(SAMPLE_RATE * NUM_CHANNELS * (BITS_PER_SAMPLE / 8), 28);
  buf.writeUInt16LE(NUM_CHANNELS * (BITS_PER_SAMPLE / 8), 32);
  buf.writeUInt16LE(BITS_PER_SAMPLE, 34);
  buf.write('data', 36);
  buf.writeUInt32LE(dataLen, 40);
  for (let i = 0; i < samples.length; i++) {
    const v = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  fs.writeFileSync(filePath, buf);
  console.log('wrote', filePath, '(' + (buf.length / 1024).toFixed(1) + ' KB)');
}

function envelope(t, dur, attack = 0.005, release = 0.04) {
  if (t < attack) return t / attack;
  const r = Math.max(release, dur * 0.2);
  if (t > dur - r) return Math.max(0, (dur - t) / r);
  return 1;
}

function sine(freq, t) {
  return Math.sin(2 * Math.PI * freq * t);
}

function damped(freq, t, decay) {
  return Math.sin(2 * Math.PI * freq * t) * Math.exp(-decay * t);
}

// trade.wav - 短促点击 (80ms)
{
  const dur = 0.08;
  const n = Math.floor(SAMPLE_RATE * dur);
  const samples = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = envelope(t, dur, 0.002, 0.02);
    samples[i] = 0.55 * env * (sine(880, t) + 0.4 * sine(1760, t) * 0.5);
  }
  writeWav(path.join(OUT_DIR, 'trade.wav'), samples);
}

// coin.wav - 金币上行双音 (150ms)
{
  const dur = 0.15;
  const n = Math.floor(SAMPLE_RATE * dur);
  const samples = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = envelope(t, dur, 0.005, 0.06);
    const f1 = 880 + 660 * Math.min(1, t / dur);
    const f2 = 1320 + 440 * Math.min(1, t / dur);
    samples[i] = 0.45 * env * (sine(f1, t) * 0.6 + sine(f2, t) * 0.4);
  }
  writeWav(path.join(OUT_DIR, 'coin.wav'), samples);
}

// news.wav - 提示双音 (200ms)
{
  const dur = 0.2;
  const n = Math.floor(SAMPLE_RATE * dur);
  const samples = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    let env;
    if (t < 0.08) env = envelope(t, 0.08, 0.005, 0.03);
    else env = envelope(t - 0.08, 0.12, 0.005, 0.04);
    const localT = t < 0.08 ? t : (t - 0.08);
    const f = t < 0.08 ? 660 : 990;
    samples[i] = 0.5 * env * sine(f, localT);
  }
  writeWav(path.join(OUT_DIR, 'news.wav'), samples);
}

// unlock.wav - 上行琶音三音 (400ms)
{
  const dur = 0.4;
  const n = Math.floor(SAMPLE_RATE * dur);
  const samples = new Float32Array(n);
  const notes = [523.25, 659.25, 783.99]; // C5 E5 G5
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const idx = Math.min(2, Math.floor(t / 0.13));
    const localT = t - idx * 0.13;
    const env = envelope(localT, 0.13, 0.005, 0.05);
    samples[i] = 0.5 * env * (sine(notes[idx], localT) + 0.3 * sine(notes[idx] * 2, localT));
  }
  writeWav(path.join(OUT_DIR, 'unlock.wav'), samples);
}

// prestige.wav - 恢弘上行和弦序列 (1.2s)
{
  const dur = 1.2;
  const n = Math.floor(SAMPLE_RATE * dur);
  const samples = new Float32Array(n);
  // C major: C E G, then F A C, then G B D
  const chords = [
    [261.63, 329.63, 392.00],
    [349.23, 440.00, 523.25],
    [392.00, 493.88, 587.33],
  ];
  const chordLen = dur / chords.length;
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const idx = Math.min(chords.length - 1, Math.floor(t / chordLen));
    const localT = t - idx * chordLen;
    const env = envelope(localT, chordLen, 0.02, chordLen * 0.4);
    let s = 0;
    for (const f of chords[idx]) {
      s += sine(f, localT) * 0.25;
      s += sine(f * 2, localT) * 0.06;
    }
    // add subtle upward sweep
    s += 0.1 * sine(440 + 600 * (localT / chordLen), localT);
    samples[i] = 0.5 * env * s;
  }
  writeWav(path.join(OUT_DIR, 'prestige.wav'), samples);
}

console.log('all sounds generated.');