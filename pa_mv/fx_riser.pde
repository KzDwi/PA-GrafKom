// =====================================================================
//  fx_riser.pde   [EFEK SUARA]
//  Suara "naik" (riser): nada sinus yang pitch-nya naik terus + desis noise,
//  menaik dari beat awal sampai beat akhir lalu mati mendadak (pas layar TV padam).
//  Disintesis langsung dengan library Sound (tidak butuh file audio).
//
//  riser = new FxRiser(this, 100, 103);   // setup()   (mulai, selesai dalam beat)
//  riser.update(clock, kontrol.isPlaying);// draw()    tiap frame
//  riser.stopNow();                       // dipanggil saat restart
//
//  Ubah: volMax (keras), fLow/fHigh (rentang pitch), noiseVol (desis).
// =====================================================================
import processing.sound.*;

class FxRiser {
  SinOsc oscA, oscB;
  WhiteNoise noiz;
  float startBeat, endBeat;
  float volMax = 0.07;     // volume puncak (lagu = VOLUME 0.1; sesuaikan)
  float noiseVol = 0.03;
  float fLow = 180, fHigh = 1700;
  boolean on = false;

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
    float f = fLow * pow(fHigh / fLow, p * p);                   // naik eksponensial
    float a = volMax * (0.15 + 0.85 * p);
    float wob = 1 + 0.012 * sin(t.beatPos * TWO_PI * 4);         // sedikit bergetar
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
