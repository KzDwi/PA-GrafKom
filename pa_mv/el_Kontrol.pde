// =====================================================================
//  el_Kontrol.pde   [KONTROL - tanpa tombol]
//  Logika restart / checkpoint. Dipanggil lewat keyboard dari pa_mv.pde.
//    R   = restart dari checkpoint
//    C   = simpan checkpoint di posisi sekarang
//    ESC = kembali ke menu
//
//  Pemakaian:
//    kontrol = new ElKontrol(lagu, clock);   // setup()
//    kontrol.show();                         // draw()  (kosong, dibiarkan untuk placeholder)
// =====================================================================
import processing.sound.*;

class ElKontrol {
  SoundFile lagu;           // file lagu yang dikontrol
  BeatClock clock;          // jam beat yang ikut di-reset saat restart
  boolean isPlaying = true; // status main (dipakai FxRiser)
  float checkpointSec = 13;  // posisi (detik) yang dipakai RESTART. 0 = awal lagu

  ElKontrol(SoundFile lagu, BeatClock clock) {
    this.lagu = lagu;
    this.clock = clock;
  }

  void show() {
    // tidak ada UI
  }

  // Simpan posisi lagu SEKARANG sebagai titik RESTART
  void setCheckpoint() {
    checkpointSec = lagu.position();
  }

  // Restart dari checkpoint & langsung PLAY
  void restartFromCheckpoint() {
    // stop() lalu jump(): jump() pada lagu yang berhenti = mulai main dari posisi itu.
    // JANGAN panggil play() lagi setelahnya (bikin lagu dobel).
    lagu.stop();
    clock.reset();
    transitionFx.reset();
    riser.stopNow();
    lagu.jump(checkpointSec);
    lagu.amp(VOLUME);
    isPlaying = true;
  }

  // Bersihkan state audio & efek, siap kembali ke menu.
  void kembaliKeMenu() {
    lagu.stop();
    // JANGAN lagu.jump(0) di sini (jump pada file stopped akan memulai playback).
    // Posisi dipaksa di mulaiLagu() saat user klik PLAY.
    clock.reset();
    transitionFx.reset();
    riser.stopNow();
    isPlaying = true;
  }
}