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
}

void draw() {
  clock.update(lagu.position() * 1000);
  background(0);

  // ===================== 1. LATAR 3D (pilih salah satu) =====================
  // Urutan if/else penting: yang rentangnya paling sempit taruh paling atas.
  if      (clock.inBeat(22, 24))                           backrooms.show(clock, 1);  // abu-abu
  
  else if (clock.inBeat(24, 40)) {
    backroomStatic.show(clock, ((clock.beat - 24) % 4) + 1);
  }
  
  else if (clock.inBeat(150, 152))                         backrooms.show(clock, 2);  // ungu
  else if (clock.inBeat(8, 40) || clock.inBeat(136, 168))  backrooms.show(clock, 0);  // kuning
  else                                                     backroomStatic.show(clock, 0); // default (ruang statis 0..3)

  // ===================== 2. ELEMENT 2D (boleh numpuk/overlap) =====================
  // Urutan panggil = urutan tumpukan (yang terakhir paling depan)
  bola.show(clock);                                // selalu tampil
  if (clock.inBeat(0, 200)) poli.show(clock);      // beat 0-199

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
}

void mousePressed() {
  kontrol.mousePressed();
}
