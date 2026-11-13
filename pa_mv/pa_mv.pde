// =====================================================================
//  pa_mv.pde  -  MAIN
//  Di sini hanya: setup element + JADWAL kapan tiap element tampil.
//  Isi tiap element ada di file el_*.pde.
// =====================================================================
import processing.sound.*;

float VOLUME = 0.2;         // volume lagu (dipakai juga saat play/restart)
int START_BEAT = 0;          // beat awal saat lagu mulai
float BPM = 162;             // BPM lagu
float OFFSET_SEC = 0.0;      // intro diam (detik) sebelum beat 0, kalau ada

ElMainMenu menu;             // menu utama
SoundFile lagu;              // file lagu
PFont fontJepang;            // font Jepang (AozoraMinchoMedium)
BeatClock clock;             // jam beat (sinkron ke lagu)
PImage pose0;                // gambar pose untuk adegan beat 24-40

// ---- daftar element ----
ElBackrooms      backrooms;
ElBackroomStatic backroomStatic;
// ElBola        bola;
// ElPolyrhythm  poli;
// ElJudul       judul;
ElLirik          lirik;
ElDebug          debug;
ElKontrol        kontrol;
ElTvStatic       tvStatic;
ElEfekVHS        efekVHS;
FxTransition     transitionFx;
ElDoorLoop       doorLoop;
ElKinetik        kinetik;
FxMosaic         mosaicFx;
FxRiser          riser;
ElVoidFall       voidFall;
ElLorongCahaya   lorongCahaya;
ElHelpMe         helpMe;
ElSpiralZoom     spiralZoom;
ElKataAkhir      kataAkhir;
ElRuangBeat      ruangBeat;
ElKolomNegatif   kolomNeg;
ElRuangTV        ruangTV;

void setup() {
  size(1280, 720, P3D);
  //surface.setResizable(true);
  surface.setLocation(100, 50);
  pixelDensity(displayDensity());

  fontJepang = createFont("AozoraMinchoMedium.ttf", 32);
  pose0 = loadImage("assets/pose0.png");
  lagu = new SoundFile(this, "assets/MainSong.mp3");
  menu = new ElMainMenu(createFont("NotoSansJP-Regular.ttf", 32), VOLUME);

  clock = new BeatClock();

  backrooms      = new ElBackrooms();
  backroomStatic = new ElBackroomStatic();
  // bola  = new ElBola(100);
  // poli  = new ElPolyrhythm(200, 60);
  // judul = new ElJudul(fontJepang, "LOOPING THE ROOM");
  lirik         = new ElLirik(fontJepang);
  debug         = new ElDebug(fontJepang);
  kontrol       = new ElKontrol(lagu, clock);
  tvStatic      = new ElTvStatic();
  efekVHS       = new ElEfekVHS();
  transitionFx  = new FxTransition();
  doorLoop      = new ElDoorLoop();
  kinetik       = new ElKinetik(fontJepang);
  mosaicFx      = new FxMosaic();
  kinetik.dimMulai = 260;   // adegan kinetik ke-2: beat 260-263 = 4 tahap redup
  riser         = new FxRiser(this, 100, 103);
  voidFall      = new ElVoidFall();
  lorongCahaya  = new ElLorongCahaya(fontJepang);
  helpMe        = new ElHelpMe();
  spiralZoom    = new ElSpiralZoom();
  kataAkhir     = new ElKataAkhir(fontJepang);
  ruangBeat     = new ElRuangBeat();
  kolomNeg      = new ElKolomNegatif();
  ruangTV       = new ElRuangTV(ruangBeat);
}

void draw() {
  if (!menu.selesai) {
    VOLUME = menu.volume;          // slider langsung mengubah VOLUME global
    menu.show();
    if (menu.selesai) mulaiLagu();
    return;
  }
  clock.update(lagu.position() * 1000);
  background(0);

// ===================== 1. LATAR 3D (pilih salah satu) =====================
  // Disusun kronologis berdasarkan beat lagu.
  if      (clock.inBeat(100, 103)) doorLoop.show(clock, 100);
  else if (clock.inBeat(103, 136)) { /* latar = adegan kinetik 2D (di bagian 2D) */ }
  else if (clock.inBeat(8, 22))    backrooms.show(clock, 0);
  else if (clock.inBeat(22, 24))   backrooms.show(clock, 1);
  else if (clock.inBeat(24, 40))   backroomStatic.show(clock, ((clock.beat - 24) % 4) + 1);

  // Beat 40-135 akan jatuh ke 'else' di bawah -> ruang statis 0 (default).

  else if (clock.inBeat(136, 150)) backrooms.show(clock, 0);  // Lorong kuning
  else if (clock.inBeat(150, 152)) backrooms.show(clock, 2);  // Lorong ungu
  else if (clock.inBeat(152, 168)) backrooms.show(clock, 0);  // Lorong kuning

  else if (clock.inBeat(168, 177)) voidFall.show3D(clock, 0); // Scene 0: kubus meledak
  else if (clock.inBeat(177, 185)) voidFall.show3D(clock, 1); // Scene 1: void partikel
  else if (clock.inBeat(185, 194)) voidFall.show3D(clock, 2); // Scene 2: lorong 3D
  else if (clock.inBeat(194, 200)) voidFall.show3D(clock, 3); // Scene 3: lorong kelas

  else if (clock.inBeat(200, 228)) lorongCahaya.show3D(clock);
  else if (clock.inBeat(264, 296)) { /* spiral zoom 2D (264-290) lalu kata akhir (290-296) */ }
  else if (clock.inBeat(231, 264)) { /* kinetik 2D ke-2 (geser +128 beat) */ }
  else if (clock.inBeat(228, 231)) { /* layar hitam 'Help Me' (digambar helpMe) */ }
  else if (clock.inBeat(296, 329)) ruangBeat.show(clock, 296, 312, 328);
  else if (clock.beat >= 329) { /* adegan bingkai blur -> TV (ruangTV, di bagian 2D) */ }

  else                             backroomStatic.show(clock, 0); // default

  // ===================== 2. ELEMENT 2D =====================
  // Urutan panggil = urutan tumpukan (terakhir = paling depan).

  // Beat 24-40: pose karakter
  if (clock.inBeat(24, 40)) {
    float poseWidth = pose0.width * 0.3;
    float poseHeight = pose0.height * 0.3;
    image(pose0, width/2.0 - poseWidth/2, height*0.72 - poseHeight/2, poseWidth, poseHeight);
  }

  // Beat 40-100: static TV bertingkat + VHS
  if (clock.inBeat(40, 49)) tvStatic.show(clock, 1);
  if (clock.inBeat(49, 56)) tvStatic.show(clock, 2);
  if (clock.inBeat(56, 72)) { tvStatic.show(clock, 3); efekVHS.show(clock); }
  if (clock.inBeat(72, 100)) { tvStatic.show(clock, 4); efekVHS.show(clock); }

  // Beat 100-136: kinetik + VHS
  if (clock.inBeat(100, 136)) efekVHS.show(clock);
  if (clock.inBeat(103, 136)) kinetik.show(clock, lirik);
  if (clock.inBeat(152, 168)) kinetik.showKolom(clock, 32);

  // Beat 168-194: void fall
  if (clock.inBeat(168, 194)) voidFall.show2D(clock);

  // Beat 200-228: lorong cahaya
  lorongCahaya.sembunyiTeks = (clock.beatPos >= 227.5);
  if (clock.inBeat(200, 228)) lorongCahaya.show2D(clock, lirik);

  // Beat 231-264: pengulangan kinetik + VHS
  if (clock.inBeat(231, 264)) efekVHS.show(clock);
  if (clock.inBeat(231, 264)) kinetik.show(clock, lirik, 128);

  // Beat 264-290: spiral zoom + VHS
  if (clock.inBeat(264, 290)) { spiralZoom.show(clock, kinetik); efekVHS.show(clock); }

  // Beat 290-296: kata akhir
  if (clock.inBeat(290, 296)) kataAkhir.show(clock, lirik);

  // Beat 312-328: kolom emas + karakter di atas ruangan 3D
  if (clock.inBeat(312, 328)) kinetik.showKolom(clock, 192);
  // if (clock.inBeat(311, 328)) kolomNeg.show(clock, 312, 328);   // matikan

  // Beat >=329: ruang TV (TV menyala, ruangan ganti tiap beat)
  if (clock.beat >= 329) ruangTV.show(clock);

  // --- Overlay: teks & transisi (di atas konten) ---

  // lirik (timing internal di el_Teks.pde)
  if (!clock.inBeat(200, 231)) lirik.show(clock);

  // Help Me (beat 227.5-231: zoom pintu, Base64 "Help Me")
  helpMe.show(clock);

  // transisi mozaik
  mosaicFx.show(clock, 102.2, 103.0, 103.0, 103.6);          // pintu -> kinetik
  mosaicFx.show(clock, 9999, 9999, 231.0, 231.6);            // Help Me -> kinetik 2
  if (clock.beatPos < 290) mosaicFx.show(clock, 289.0, 290.0, 9999, 9999); // spiral -> hitam
  mosaicFx.show(clock, 295.35, 296.0, 296.0, 296.7);         // kata akhir -> ruang 3D

  // transisi umum + glitch (paling depan, di bawah UI)
  transitionFx.show();
  transitionFx.showGlitch();

  // ===================== 3. UI =====================
  // kontrol.show();
  // debug.show(clock);

  // ===================== 4. EVENT SEKALI (switch per beat) =====================
  // ---- GLITCH (jadwal dalam SUBBEAT; 1 beat = 2 subbeat) ----
  if (clock.atSubBeat(14))  transitionFx.triggerGlitch();   // Beat 7
  if (clock.atSubBeat(15))  transitionFx.triggerGlitch();   // Beat 7.5
  if (clock.atSubBeat(142)) transitionFx.triggerGlitch();   // Beat 71
  if (clock.atSubBeat(158)) transitionFx.triggerGlitch();   // Beat 79
  if (clock.atSubBeat(174)) transitionFx.triggerGlitch();   // Beat 87
  if (clock.atSubBeat(191)) transitionFx.triggerGlitch();   // Beat 95.5
  if (clock.atSubBeat(203)) transitionFx.triggerGlitch();   // Beat 101.5
  if (clock.atSubBeat(238)) transitionFx.triggerGlitch();   // Beat 119
  if (clock.atSubBeat(271)) transitionFx.triggerGlitch();   // Beat 135.5
  if (clock.atSubBeat(494)) transitionFx.triggerGlitch();   // Beat 247 (kinetik ke-2)
  if (clock.atSubBeat(527)) transitionFx.triggerGlitch();   // Beat 263.5 (kinetik ke-2)
  // error singkat di akhir scene kartu (beat 328-329) dan di awal error TV (343)
  if (clock.atSubBeat(656)) transitionFx.triggerGlitch();   // Beat 328
  if (clock.atSubBeat(657)) transitionFx.triggerGlitch();   // Beat 328.5
  if (clock.atSubBeat(658)) transitionFx.triggerGlitch();   // Beat 329 (bingkai muncul)
  if (clock.atSubBeat(686)) transitionFx.triggerGlitch();   // Beat 343 (error TV mulai)
  if (clock.atSubBeat(687)) transitionFx.triggerGlitch();   // Beat 343.5

  // transisi per beat (flash / presser / cahaya)
  if (clock.newBeat) {
    switch (clock.beat) {
      case 99:  transitionFx.triggerPresser(); break;   // masuk room 3
      case 55:  transitionFx.trigger();        break;   // flash kuning
      case 197: transitionFx.triggerLight();   break;   // cahaya dari tengah
    }
  }
}

void mulaiLagu() {
  if (lagu == null) return;
  if (!lagu.isPlaying()) lagu.loop();
  lagu.amp(VOLUME);

  if (START_BEAT > 0) {
    float sec = OFFSET_SEC + START_BEAT * (60.0 / BPM);
    lagu.jump(sec);
  }
}

void mousePressed() {
  if (!menu.selesai) { menu.mousePressed(); return; }
}

void mouseDragged()  { if (!menu.selesai) menu.mouseDragged(); }
void mouseReleased() { if (!menu.selesai) menu.mouseReleased(); }

void keyPressed() {
  if (!menu.selesai) {
    if (key == ENTER || key == RETURN || key == ' ') menu.tekanPlay();
    return;
  }
  if (key == 'c' || key == 'C') kontrol.setCheckpoint();
  if (key == 'r' || key == 'R') kontrol.restartFromCheckpoint();
  if (key == ESC) {
    key = 0;                 // cegah Processing menutup sketch
    if (menu.selesai) {
      kontrol.kembaliKeMenu();
      menu.reset();
    }
  }
}