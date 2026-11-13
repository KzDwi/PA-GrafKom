// =====================================================================
//  fx_riser.pde   [EFEK SUARA]
//  Suara "riser": nada sinus yang pitch-nya naik terus + desis noise,
//  menaik dari beat awal sampai beat akhir lalu mati mendadak
//  (pas layar TV padam). Disintesis lewat library Sound, tanpa file audio.
//
//  Pemakaian:
//    riser = new FxRiser(this, 100, 103);       // setup()
//    riser.update(clock, kontrol.isPlaying);    // draw() tiap frame
//    riser.stopNow();                           // saat restart
// =====================================================================
import processing.sound.*;

class FxRiser {
  SinOsc oscA, oscB;           // dua sinus (oscB = harmonik 1.5x oscA)
  WhiteNoise noiz;             // noise untuk desis
  float startBeat, endBeat;    // rentang beat aktif
  float volMax = 0.07;         // volume puncak (sesuaikan dengan VOLUME lagu)
  float noiseVol = 0.03;       // volume noise maksimum
  float fLow = 180, fHigh = 1700;  // rentang pitch (Hz) dari awal ke akhir
  boolean on = false;          // true = sedang berbunyi

  FxRiser(PApplet app, float startBeat, float endBeat) {
    this.startBeat = startBeat;
    this.endBeat = endBeat;
    oscA = new SinOsc(app);
    oscB = new SinOsc(app);
    noiz = new WhiteNoise(app);
  }

  void update(BeatClock t, boolean playing) {
    boolean want = playing && t.beatPos >= startBeat && t.beatPos < endBeat;
    if (!want) { stopNow(); return; }
    float p = (t.beatPos - startBeat) / (endBeat - startBeat);   // 0..1
    float f = fLow * pow(fHigh / fLow, p * p);                   // pitch naik eksponensial
    float a = volMax * (0.15 + 0.85 * p);                        // volume naik pelan
    float wob = 1 + 0.012 * sin(t.beatPos * TWO_PI * 4);         // sedikit getar
    if (!on) {
      oscA.play(f, a);
      oscB.play(f * 1.5 * wob, a * 0.5);
      noiz.play(noiseVol * p);
      on = true;
    } else {
      oscA.freq(f);          oscA.amp(a);
      oscB.freq(f * 1.5 * wob); oscB.amp(a * 0.5);
      noiz.amp(noiseVol * p);
    }
  }

  void stopNow() {
    if (!on) return;
    oscA.stop(); oscB.stop(); noiz.stop();
    on = false;
  }
}