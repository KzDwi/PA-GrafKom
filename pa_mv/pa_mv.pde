// =====================================================================
//  pa_mv.pde  -  MAIN
//  Di sini hanya: setup element + JADWAL kapan tiap element tampil.
//  Isi tiap element ada di file el_*.pde
// =====================================================================
import processing.sound.*;

SoundFile lagu;
PFont fontJepang;
BeatClock clock;

// ---- daftar element ----
ElBackrooms  backrooms;
ElBackroomStatic backroomStatic;
ElBola       bola;
ElPolyrhythm poli;
ElJudul      judul;
ElLirik      lirik;
ElDebug      debug;
ElKontrol    kontrol;
ElTvStatic   tvStatic;
ElEfekVHS    efekVHS;
FxTransition transitionFx;

void setup() {
  size(1280, 720, P3D);
  //surface.setResizable(true);
  surface.setLocation(100, 50);
  pixelDensity(displayDensity());

  fontJepang = createFont("NotoSansJP-Regular.ttf", 32);
  lagu = new SoundFile(this, "assets/MainSong.mp3");
  lagu.play();
  lagu.amp(0.1); // buat test aja
  
  clock = new BeatClock();

  backrooms = new ElBackrooms();
  backroomStatic = new ElBackroomStatic();
  bola      = new ElBola(100);
  poli      = new ElPolyrhythm(200, 60);
  judul     = new ElJudul(fontJepang, "LOOPING THE ROOM");
  lirik     = new ElLirik(fontJepang);
  debug     = new ElDebug(fontJepang);
  kontrol   = new ElKontrol(lagu, clock);
  tvStatic  = new ElTvStatic();
  efekVHS   = new ElEfekVHS();
  transitionFx = new FxTransition();
}

void draw() {
  clock.update(lagu.position() * 1000);
  background(0);

// ===================== 1. LATAR 3D (pilih salah satu) =====================
  // Disusun berurutan (kronologis) berdasarkan ketukan (beat) lagu
  if      (clock.inBeat(8, 22))    backrooms.show(clock, 0);  // Beat 8-21: Lorong kuning
  else if (clock.inBeat(22, 24))   backrooms.show(clock, 1);  // Beat 22-23: Lorong abu-abu
  else if (clock.inBeat(24, 40))   backroomStatic.show(clock, ((clock.beat - 24) % 4) + 1); // Beat 24-39: Ruang statis berganti-ganti
  
  // (Beat 40 - 135 akan otomatis jatuh ke 'else' di bawah, yaitu ruang statis 0)
  
  else if (clock.inBeat(136, 150)) backrooms.show(clock, 0);  // Beat 136-149: Lorong kuning
  else if (clock.inBeat(150, 152)) backrooms.show(clock, 2);  // Beat 150-151: Lorong ungu
  else if (clock.inBeat(152, 168)) backrooms.show(clock, 0);  // Beat 152-167: Lorong kuning
  
  else                             backroomStatic.show(clock, 0); // Waktu kosong / sisanya: Default (ruang statis 0)

  // ===================== 2. ELEMENT 2D (boleh numpuk/overlap) =====================
  // Urutan panggil = urutan tumpukan (yang terakhir paling depan)
  bola.show(clock);                                // selalu tampil
  if (clock.inBeat(0, 200)) poli.show(clock);      // beat 0-199
  
  //40,47
  if (clock.inBeat(40, 49)) {
  tvStatic.show(clock,1);
  }
 
  //46-54
  if (clock.inBeat(49, 56)) {
  tvStatic.show(clock,2);
  }
  
  //46-54
  if (clock.inBeat(56, 72)) {
  tvStatic.show(clock,3);
  efekVHS.show(clock);
  }
  
  //46-54
  if (clock.inBeat(72, 100)) {
  tvStatic.show(clock,4);
  efekVHS.show(clock);
  }


  transitionFx.show();
  judul.show(clock);
  lirik.show(clock);                               // timing lirik diatur di el_Teks.pde
  

  // ===================== 3. UI =====================
  kontrol.show();
  debug.show(clock);

  // ===================== 4. EVENT SEKALI (di sini switch cocok) =====================
  // if (clock.newBeat) {
  //   switch (clock.beat) {
  //     case 64: /* sesuatu yang cuma sekali di beat 64 */ break;
  //     case 96: /* ... */ break;
  //   }
  // }
  
  // ===================== 4. EVENT SEKALI (di sini switch cocok) =====================
  if (clock.newBeat) {
    switch (clock.beat) {
      case 99: 
        transitionFx.triggerPresser();; // Ledakan flash masuk ke room 3
        break;
      case 55: 
        transitionFx.trigger(); // Ledakan flash masuk ke room 3
        break;
    }
  }
}



void mousePressed() {
  kontrol.mousePressed();
}
