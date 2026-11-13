// =====================================================================
//  pa_mv.pde  -  MAIN
//  Di sini hanya: setup element + JADWAL kapan tiap element tampil.
//  Isi tiap element ada di file el_*.pde
// =====================================================================
import processing.sound.*;

float VOLUME = 0.1;      // volume lagu (dipakai juga saat play/restart)
ElMainMenu menu;   
SoundFile lagu;
PFont fontJepang;
BeatClock clock;
PImage pose0;

// ---- daftar element ----
ElBackrooms  backrooms;
ElBackroomStatic backroomStatic;
// ElBola       bola;
// ElPolyrhythm poli;
// ElJudul      judul;
ElLirik      lirik;
ElDebug      debug;
ElKontrol    kontrol;
ElTvStatic   tvStatic;
ElEfekVHS    efekVHS;
FxTransition transitionFx;
ElDoorLoop   doorLoop;    
ElKinetik    kinetik;    
FxMosaic     mosaicFx;   
FxRiser      riser;       
ElVoidFall   voidFall;
ElLorongCahaya lorongCahaya;
ElHelpMe    helpMe;
ElSpiralZoom spiralZoom;
ElKataAkhir  kataAkhir;
ElRuangBeat  ruangBeat;
ElKolomNegatif kolomNeg;
ElRuangTV    ruangTV;

void setup() {
  size(1280, 720, P3D);
  //surface.setResizable(true);
  surface.setLocation(100, 50);
  pixelDensity(displayDensity());

  fontJepang = createFont("NotoSansJP-Regular.ttf", 32);
  pose0 = loadImage("assets/pose0.png");
  lagu = new SoundFile(this, "assets/MainSong.mp3");
  menu = new ElMainMenu(fontJepang, VOLUME);
  
  clock = new BeatClock();

  backrooms = new ElBackrooms();
  backroomStatic = new ElBackroomStatic();
  // bola      = new ElBola(100);
  // poli      = new ElPolyrhythm(200, 60);
  // judul     = new ElJudul(fontJepang, "LOOPING THE ROOM");
  lirik     = new ElLirik(fontJepang);
  debug     = new ElDebug(fontJepang);
  kontrol   = new ElKontrol(lagu, clock);
  tvStatic  = new ElTvStatic();
  efekVHS   = new ElEfekVHS();
  transitionFx = new FxTransition();
  doorLoop  = new ElDoorLoop();
  kinetik   = new ElKinetik(fontJepang);
  mosaicFx = new FxMosaic();
  kinetik.dimMulai = 260;   // adegan kinetik ke-2: beat 260-263 = 4 tahap redup (kolom emas pindah kiri -> kanan)
  riser     = new FxRiser(this, 100, 103);   
  voidFall  = new ElVoidFall();
  lorongCahaya = new ElLorongCahaya(fontJepang);
  helpMe       = new ElHelpMe();
  spiralZoom   = new ElSpiralZoom();
  kataAkhir    = new ElKataAkhir(fontJepang);
  ruangBeat    = new ElRuangBeat();
  kolomNeg     = new ElKolomNegatif();
  ruangTV      = new ElRuangTV(ruangBeat);
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
  // Disusun berurutan (kronologis) berdasarkan ketukan (beat) lagu
  if      (clock.inBeat(100, 103)) doorLoop.show(clock, 100);   
  else if (clock.inBeat(103, 136)) { /* latar = adegan kinetik 2D (digambar di bagian 2D) */ }
  else if (clock.inBeat(8, 22))    backrooms.show(clock, 0);  
  else if (clock.inBeat(22, 24))   backrooms.show(clock, 1);  
  else if (clock.inBeat(24, 40))   backroomStatic.show(clock, ((clock.beat - 24) % 4) + 1); 
  
  // (Beat 40 - 135 akan otomatis jatuh ke 'else' di bawah, yaitu ruang statis 0)
  
  else if (clock.inBeat(136, 150)) backrooms.show(clock, 0);  // Beat 136-149: Lorong kuning
  else if (clock.inBeat(150, 152)) backrooms.show(clock, 2);  // Beat 150-151: Lorong ungu
  else if (clock.inBeat(152, 168)) backrooms.show(clock, 0);  // Beat 152-167: Lorong kuning
  
  else if (clock.inBeat(168, 177)) voidFall.show3D(clock, 0); // Scene 0: Kubus meledak perlahan
  else if (clock.inBeat(177, 185)) voidFall.show3D(clock, 1); // Scene 1: Void partikel saja
  else if (clock.inBeat(185, 194)) voidFall.show3D(clock, 2); // Scene 2: Lorong 3D jalan
  else if (clock.inBeat(194, 200))   voidFall.show3D(clock, 3); // Scene 3: Tabrakan/Transisi
  
  else if (clock.inBeat(200, 228)) lorongCahaya.show3D(clock);
  else if (clock.inBeat(264, 297)) { /* latar = spiral zoom 2D (264-290) lalu layar hitam kata akhir (290-297) */ }
  else if (clock.inBeat(231, 264)) { /* latar = adegan kinetik 2D ke-2 (pemakaian ulang, geser +128 beat) */ }
  else if (clock.inBeat(228, 231)) { /* latar = layar hitam 'Help Me' (digambar helpMe di bagian akhir) */ }
  else if (clock.inBeat(297, 329)) ruangBeat.show(clock, 297, 312, 328);   // beat 297-328: 1 ruangan Backrooms per beat (kartu emas di 312-328, error di 328-329)
  else if (clock.beat >= 329) { /* latar = adegan bingkai blur -> TV (ruangTV, 2D, digambar di bagian 2D) */ }
  
  else                             backroomStatic.show(clock, 0); // Waktu kosong / sisanya: Default (ruang statis 0)

  // ===================== 2. ELEMENT 2D (boleh numpuk/overlap) =====================
  // Urutan panggil = urutan tumpukan (yang terakhir paling depan)
  if (clock.inBeat(312, 328)) kolomNeg.show(clock, 312, 328);   // kartu emas transparan loncat per beat (ruangan tetap ganti tiap beat) (di atas latar 3D, di bawah teks)

  // if (!clock.inBeat(100, 136) && clock.beat < 168) bola.show(clock); // bola disembunyikan di adegan pintu & kinetik
  // if (clock.inBeat(0, 200)) poli.show(clock);      // beat 0-199
  if (clock.inBeat(24, 40)) {
  float poseWidth = pose0.width * 0.3;
  float poseHeight = pose0.height * 0.3;
  image(pose0, width / 2.0 - poseWidth / 2, height * 0.72 - poseHeight / 2, poseWidth, poseHeight);
}


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


  // , beat 103-136
  if (clock.inBeat(103, 136)) kinetik.show(clock, lirik);
  if (clock.inBeat(100, 136)) efekVHS.show(clock);  // grain/scanline di pintu & kinetik

  // pengulangan adegan kinetik (spiral "Kurikaesu"): beat 231-263 = beat 103-135 digeser +128
  if (clock.inBeat(231, 264)) kinetik.show(clock, lirik, 128);
  if (clock.inBeat(231, 264)) efekVHS.show(clock);

  // beat 264-289: spiral FULL layar + kamera zoom (kiri-bawah -> atas-kanan -> semula)
  if (clock.inBeat(264, 290)) { spiralZoom.show(clock, kinetik); efekVHS.show(clock); }
  
  lorongCahaya.sembunyiTeks = (clock.beatPos >= 227.5);   // subBeat 455: teks lirik hilang saat zoom ke pintu
  if (clock.inBeat(200, 228)) lorongCahaya.show2D(clock, lirik);
  
  if (clock.inBeat(168, 194)) {
    voidFall.show2D(clock); // Otomatis menyesuaikan scene yang diset oleh show3D
  }

  // beat 329-343 bingkai blur zoom out -> 343-344.5 error hitam-putih -> TV menyala (ruangan ganti tiap beat, blur + redup)
  if (clock.beat >= 329) ruangTV.show(clock);

  transitionFx.show();
  // judul.show(clock);
  if (!clock.inBeat(200, 231)) lirik.show(clock);                            // timing lirik diatur di el_Teks.pde
  transitionFx.showGlitch();                       // glitch satu layar (di atas semua, di bawah UI)

  // Transisi mozaik "TV rabun": pintu -> kotak-kotak makin besar -> gelap (102.2 -> 103.0),
  // lalu adegan baru muncul dari kotak besar -> jelas (103.0 -> 103.6)
  mosaicFx.show(clock, 102.2, 103.0, 103.0, 103.6);

  // Beat 227.5 (subBeat 455) -> 231: zoom ke pintu, layar hitam + distorsi putih, teks Base64 "Help Me"
  helpMe.show(clock);
  mosaicFx.show(clock, 9999, 9999, 231.0, 231.6);   // dari hitam 'Help Me' -> kotak besar -> adegan kinetik ke-2 jelas
  if (clock.beatPos < 290) mosaicFx.show(clock, 289.0, 290.0, 9999, 9999);   // spiral -> kotak besar -> hitam (beat 289-290)
  mosaicFx.show(clock, 296.35, 297.0, 297.0, 297.7);   // kata akhir merah -> kotak besar -> ruangan 3D (beat 297)

  // Beat 290-297: layar hitam, distorsi tipis dari atas, lirik muncul huruf demi huruf, jadi merah di beat 296
  if (clock.inBeat(290, 297)) kataAkhir.show(clock, lirik);
  //riser.update(clock, kontrol.isPlaying);          // suara naik beat 100-103 (diam saat pause)
  

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
  // ---- GLITCH (jadwal dalam SUBBEAT; 1 beat = 2 subbeat) ----
  if (clock.atSubBeat(14)) transitionFx.triggerGlitch();   // baet 7 :
  if (clock.atSubBeat(15)) transitionFx.triggerGlitch();   // baet 7 :
  if (clock.atSubBeat(142)) transitionFx.triggerGlitch();  // Beat 71  : 
  if (clock.atSubBeat(158)) transitionFx.triggerGlitch();  // Beat 79  : 
  if (clock.atSubBeat(174)) transitionFx.triggerGlitch();  // Beat 87  : 
  if (clock.atSubBeat(191)) transitionFx.triggerGlitch();  // Beat 95.5: 
  if (clock.atSubBeat(203)) transitionFx.triggerGlitch();  // Beat 101.5: 
  if (clock.atSubBeat(238)) transitionFx.triggerGlitch();  // Beat 117.5:
  if (clock.atSubBeat(271)) transitionFx.triggerGlitch();  // Beat 136  : 
  if (clock.atSubBeat(494)) transitionFx.triggerGlitch();  // Beat 247  : (= 238 + 256, kinetik ke-2)
  if (clock.atSubBeat(527)) transitionFx.triggerGlitch();  // Beat 263.5: (= 271 + 256, kinetik ke-2)
  // error singkat di akhir scene kartu (beat 328-329) dan di awal error TV (beat 343-343.5)
  if (clock.atSubBeat(656)) transitionFx.triggerGlitch();   // Beat 328
  if (clock.atSubBeat(657)) transitionFx.triggerGlitch();   // Beat 328.5
  if (clock.atSubBeat(658)) transitionFx.triggerGlitch();   // Beat 329 : bingkai muncul
  if (clock.atSubBeat(686)) transitionFx.triggerGlitch();   // Beat 343 : mulai error hitam-putih
  if (clock.atSubBeat(687)) transitionFx.triggerGlitch();   // Beat 343.5
  // (posisi anak untuk tiap teleport diatur di el_tvstatic.pde -> boySub / boyStartX)

  if (clock.newBeat) {
    switch (clock.beat) {
      case 99: 
        transitionFx.triggerPresser();; // Ledakan flash masuk ke room 3
        break;
      case 55: 
        transitionFx.trigger(); // Ledakan flash masuk ke room 3
        break;
      case 197: 
        transitionFx.triggerLight(); // Ledakan flash masuk ke room 3
        break;
    }
  }
}

void mulaiLagu() {
  if (lagu == null) return;
  if (!lagu.isPlaying()) {
    lagu.loop();       // loop() restart dari awal → tidak dobel
  }
  lagu.amp(VOLUME);    // setelah loop() supaya volume tidak ter-reset
}

void mousePressed() {
  if (!menu.selesai) { menu.mousePressed(); return; }
  kontrol.mousePressed();
}
void mouseDragged()  { if (!menu.selesai) menu.mouseDragged(); }
void mouseReleased() { menu.mouseReleased(); }

void keyPressed() {
  if (!menu.selesai) {
    if (key == ENTER || key == RETURN || key == ' ') menu.tekanPlay();
    return;
  }
  if (key == 'c' || key == 'C') kontrol.setCheckpoint();
  if (key == ESC) {
    key = 0;                 // ⚠ wajib: cegah Processing menutup sketch
    if (menu.selesai) {      // hanya jika sedang di dalam "game"
      kontrol.kembaliKeMenu();
      menu.reset();
    }
  }
}
