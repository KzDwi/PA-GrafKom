// =====================================================================
//  core_BeatClock.pde
//  Jam beat. Di-update SEKALI per frame di draw(), lalu dikirim ke semua element.
//  Menggantikan AudioManager.pde lama.
// =====================================================================
class BeatClock {
  float bpm = 162;
  float beatDuration;          // ms per beat

  float posMs;                 // posisi lagu (ms)
  float beatPos;               // posisi lagu dalam beat (pecahan, mis. 12.37)
  float frac;                  // 0..1 progres di dalam beat sekarang

  int beat, subBeat, quarterBeat, eighthBeat;   // 1/1, 1/2, 1/4, 1/8
  boolean newBeat = false;     // true hanya di frame pertama saat beat berganti

  int lastBeat = -1;

  BeatClock() {
    beatDuration = 60000.0 / bpm;
  }

  void update(float posMs) {
    this.posMs  = posMs;
    beatPos     = posMs / beatDuration;
    beat        = (int) beatPos;
    frac        = beatPos - beat;
    subBeat     = (int) (posMs / (beatDuration / 2));
    quarterBeat = (int) (posMs / (beatDuration / 4));
    eighthBeat  = (int) (posMs / (beatDuration / 8));

    newBeat  = (beat != lastBeat);
    lastBeat = beat;
  }

  // dipanggil saat lagu di-restart / lompat
  void reset() {
    lastBeat = -1;
  }

  // beat sekarang ada di rentang [dari, sampai) ?   contoh: inBeat(8, 40)
  boolean inBeat(int dari, int sampai) {
    return beat >= dari && beat < sampai;
  }

  // TRUE sekali saja, tepat saat beat n baru mulai (untuk event satu kali)
  boolean atBeat(int n) {
    return newBeat && beat == n;
  }

  // progres 0..1 di dalam rentang beat (untuk animasi fade/zoom dsb)
  float progress(int dari, int sampai) {
    return constrain((beatPos - dari) / (float) (sampai - dari), 0, 1);
  }
}
