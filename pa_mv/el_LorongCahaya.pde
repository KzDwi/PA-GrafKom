// =====================================================================
//  el_LorongCahaya.pde   [ELEMENT 3D & 2D TERPISAH]
//  Adegan beat 200-228 (ref. video: lorong gelap yang berkedip).
//    - Lorong gelap + plafon kotak. Tiap `kilatTiap` beat ada KILAT:
//      lorong menyala sebentar, di ujungnya bola cahaya, lalu redup sampai hitam.
//      Tiap kilat sudut lorong berganti (loncat maju), makin lama makin lebar.
//    - Lirik muncul HURUF DEMI HURUF (meloncat lalu mendarat) di tengah layar.
//    - Beat archMulai: bola cahaya jadi pintu lengkung gelap + monster raksasa.
//    - Beat glitchMulai: glitch (pita warna berundak, lempeng putih).
//
//  Teks lirik DIAMBIL dari ElLirik (lirik[] & lirikBeat[]) - tidak ditulis ulang.
//  Semua gerak dihitung dari clock.beatPos -> aman saat pause / restart.
//
//  Pemakaian:
//    lorongCahaya = new ElLorongCahaya(fontJepang);   // setup()
//    lorongCahaya.show3D(clock);                       // draw(), bagian "1. LATAR 3D"
//    lorongCahaya.show2D(clock, lirik);                // draw(), bagian "2. ELEMENT 2D"
// =====================================================================
class ElLorongCahaya {
  PFont font;                          // font untuk lirik
  Canvas3D cv3d = new Canvas3D(2);     // kanvas offscreen 3D (zoom 2x)
  PImage orbImg;                       // tekstur bola cahaya (dibuat sekali)
  PImage bacteria;                     // tekstur monster di ujung lorong
  float beatPosNow = 0;                // salinan beatPos terakhir
  float lihatMuka  = 0;                // 0 = lihat kaki, 1 = lihat muka monster

  // ---- MONSTER BESAR ----
  float monsterH        = 800;   // tinggi monster (unit dunia). Lorong tingginya 200, jadi raksasa
  float monsterFaceFrac = 0.18;  // posisi muka dari ATAS gambar (0 = puncak, 1 = kaki)
  float monsterTurun    = 140;   // jarak kaki monster di bawah lantai (efek menjulang)

  // ---- JADWAL (beat) ----
  float mulai       = 200;   // adegan mulai: kilat pertama + baris lirik pertama
  float archMulai   = 226;   // bola cahaya berubah jadi pintu lengkung
  float glitchMulai = 228;   // glitch + huruf terakhir menumpuk
  float kilatTiap   = 2;     // jarak antar kilat (beat)
  float[] pola = { 1.0, 0.45, 0.85, 0.45 };   // kuat tiap kilat (berulang)

  // ---- hasil hitungan tiap frame (diisi calc()) ----
  float kilat;               // 0..1 terang saat ini
  float hitU;                // beat sejak kilat terakhir
  float archU;               // beat sejak archMulai
  int   fase;                // 0 = lorong berkedip | 1 = pintu lengkung | 2 = glitch
  int   tembakan;            // nomor kilat (untuk variasi lorong)
  float lebarLorong = 140;   // lebar lorong saat ini
  float camX, camY;          // posisi kamera (X & Y)
  boolean sembunyiTeks = false;   // true = teks lirik tidak digambar (dipakai ElHelpMe)

  ElLorongCahaya(PFont font) {
    this.font = font;
    bacteria = loadImage("assets/bacteria.png");
    if (bacteria == null) println("⚠ assets/bacteria.png tidak ditemukan");
    buildOrb();
  }

  // ===================================================================
  //  FUNGSI 1: lorong 3D  (dipanggil di bagian "1. LATAR 3D")
  // ===================================================================
  void show3D(BeatClock t) {
    calc(t);
    PGraphics g = cv3d.begin();
    g.background(0);
    if (fase < 2 && kilat > 0.01) {
      drawLorong(g, kilat);
    }
    cv3d.end();
  }

  // ===================================================================
  //  FUNGSI 2: bola cahaya + teks  (dipanggil di bagian "2. ELEMENT 2D")
  // ===================================================================
  void show2D(BeatClock t, ElLirik l) {
    calc(t);
    pushStyle();
    hint(DISABLE_DEPTH_TEST);
    noLights();

    if (fase < 2) drawOrb();
    else          drawGlitch(t);

    if (!sembunyiTeks) drawText(t, l);

    hint(ENABLE_DEPTH_TEST);
    popStyle();
  }

  // ===================================================================
  //  HITUNGAN WAKTU (semua dari beatPos)
  // ===================================================================
  void calc(BeatClock t) {
    beatPosNow = t.beatPos;
    float rel = t.beatPos - mulai;
    if (rel < 0) { kilat=0; hitU=0; archU=0; fase=0; tembakan=0; lihatMuka=0; return; }

    tembakan = (int) (rel / kilatTiap);
    hitU     = rel - tembakan * kilatTiap;
    archU    = t.beatPos - archMulai;

    kilat  = pola[tembakan % pola.length] * exp(-3.0 * hitU);   // memudar eksponensial
    kilat *= 0.92 + 0.08 * sin(hitU * 70);                      // getar halus

    fase = (t.beatPos >= glitchMulai) ? 2 : ((t.beatPos >= archMulai) ? 1 : 0);
    if (fase == 1) {
      float naik = 0.35 + 0.65 * sst(227.0, 227.9, t.beatPos);
      if (t.beatPos >= 227.0) kilat = max(kilat, naik);         // fase arch: cahaya tidak terlalu redup
    }
    if (fase == 2) kilat = 1;
    kilat = constrain(kilat, 0, 1);

    lebarLorong = lerp(140, 330, sst(2, 9, tembakan));          // lorong makin lebar
    camX = (hs(tembakan * 5 + 1) - 0.5) * 40;                   // geser kamera X acak tapi deterministik
    camY = (hs(tembakan * 9 + 2) - 0.5) * 14;

    // KAMERA NAIK: 227.0 -> 227.95 smoothstep
    lihatMuka = (fase == 1) ? sst(227.0, 227.95, t.beatPos) : 0;
  }

  // ===================================================================
  //  LORONG 3D (digambar ke kanvas offscreen g)
  //  Cahaya datang dari ujung lorong: makin jauh makin terang.
  // ===================================================================
  void drawLorong(PGraphics g, float lum) {
    final float H=100, LEN=420; final int N=6; final float SEG=LEN/N;
    float wH = lebarLorong;                       // setengah lebar lorong

    // ▼ KAMERA
    float footY = H + monsterTurun;
    float camYNow    = camY;
    float targetYNow = camY;
    if (fase == 1) {
      float faceY = (footY - monsterH) + monsterH * monsterFaceFrac;   // tinggi muka monster
      targetYNow = lerp(camY, faceY, lihatMuka);   // lurus ke depan -> muka
      camYNow    = lerp(camY, -55,   lihatMuka);
    }

    g.perspective(radians(62 - 4 * constrain(hitU/2.0, 0, 1)), (float)width/height, 5, 3000);
    g.camera(camX, camYNow, 0,  camX, targetYNow, -LEN,  0, 1, 0);
    g.noLights(); g.noStroke();

    for (int i = 0; i < N; i++) {
      float z0 = -i * SEG;
      float z1 = -(i + 1) * SEG;
      float zc = (z0 + z1) / 2;
      float fb = lum * (0.22 + 0.78 * pow((i + 1) / (float) N, 1.6));   // kecerahan per segmen
      int world = tembakan * 3 + i;

      // lantai karpet
      g.fill(70 * fb, 62 * fb, 40 * fb);
      g.beginShape(QUADS);
      g.vertex(-wH, H, z0); g.vertex(wH, H, z0); g.vertex(wH, H, z1); g.vertex(-wH, H, z1);
      g.endShape();

      // plafon
      g.fill(105 * fb, 100 * fb, 78 * fb);
      g.beginShape(QUADS);
      g.vertex(-wH, -H, z0); g.vertex(wH, -H, z0); g.vertex(wH, -H, z1); g.vertex(-wH, -H, z1);
      g.endShape();

      // dinding kiri & kanan
      g.fill(100 * fb, 92 * fb, 58 * fb);
      g.beginShape(QUADS);
      g.vertex(-wH, -H, z0); g.vertex(-wH, H, z0); g.vertex(-wH, H, z1); g.vertex(-wH, -H, z1);
      g.vertex( wH, -H, z0); g.vertex( wH, H, z0); g.vertex( wH, H, z1); g.vertex( wH, -H, z1);
      g.endShape();

      // pintu (acak tapi tetap sama tiap diputar)
      if (hs(world * 2 + 1) > 0.40) drawPintu(g, -wH + 1, zc, fb, 1);
      if (hs(world * 2 + 2) > 0.50) drawPintu(g,  wH - 1, zc, fb, -1);

      // kotak rendah di dasar dinding (hanya kalau lorong sudah lebar)
      if (wH > 200 && hs(world * 3 + 5) > 0.75) {
        g.pushMatrix();
        g.translate(wH - 26, H - 14, zc);
        g.fill(40 * fb, 34 * fb, 24 * fb);
        g.box(40, 28, 40);
        g.popMatrix();
      }

      // garis kisi plafon
      g.stroke(235 * fb, 228 * fb, 200 * fb);
      g.strokeWeight(1.5);
      g.line(-wH, -H + 0.5, z0, wH, -H + 0.5, z0);
      for (int j = 1; j < 4; j++) {
        float x = -wH + j * (2 * wH / 4);
        g.line(x, -H + 0.5, z0, x, -H + 0.5, z1);
      }
      g.noStroke();
    }

    // dinding ujung lorong (paling jauh)
    g.fill(25 * lum, 22 * lum, 14 * lum);
    g.beginShape(QUADS);
    g.vertex(-wH, -H, -LEN); g.vertex(wH, -H, -LEN); g.vertex(wH, H, -LEN); g.vertex(-wH, H, -LEN);
    g.endShape();

    // monster (hanya fase 1 ke atas)
    if (fase >= 1 && bacteria != null) {
      drawMonsterBesar(g, LEN, H);
    }
  }

  // Monster raksasa di ujung lorong. Kaki berpijak di lantai, orb jadi
  // backlight di belakangnya. Keduanya ikut terang-redup mengikuti kilat.
  void drawMonsterBesar(PGraphics g, float LEN, float H) {
    float am = sst(0, 0, archU);          // 0 di awal, 1 di akhir
    if (am < 0.001) return;

    float hM = monsterH * am;
    float wM = hM * bacteria.width / (float) bacteria.height;   // jaga aspek
    float zO = -LEN + 2;                  // z orb (di belakang monster)
    float zM = -LEN + 4;                  // z monster
    float footY = H + monsterTurun;

    g.hint(DISABLE_DEPTH_TEST);           // supaya tidak terpotong plafon/dinding
    g.noStroke();
    // MONSTER: kaki di lantai (y = footY), tubuh menjulang ke atas
    g.tint(255 * kilat, 240 * kilat, 205 * kilat);   // putih hangat x kilat
    g.beginShape(QUADS);
    g.texture(bacteria);
    g.vertex(-wM / 2, footY - hM, zM, 0,              0);
    g.vertex( wM / 2, footY - hM, zM, bacteria.width, 0);
    g.vertex( wM / 2, footY,      zM, bacteria.width, bacteria.height);
    g.vertex(-wM / 2, footY,      zM, 0,              bacteria.height);
    g.endShape();
    g.noTint();

    g.hint(ENABLE_DEPTH_TEST);
  }

  // Pintu gelap menempel di dinding. `sisi` = 1 (kiri) / -1 (kanan),
  // `x` = posisi dinding, `zc` = z tengah pintu, `fb` = faktor kecerahan.
  void drawPintu(PGraphics g, float x, float zc, float fb, int sisi) {
    float dz = 16;                        // setengah lebar pintu
    float yAtas = -45;
    float yBawah = 100;
    // bingkai (sedikit lebih terang)
    g.fill(60 * fb, 55 * fb, 35 * fb);
    g.beginShape(QUADS);
    g.vertex(x, yAtas - 4, zc - dz - 3); g.vertex(x, yAtas - 4, zc + dz + 3);
    g.vertex(x, yBawah,    zc + dz + 3); g.vertex(x, yBawah,    zc - dz - 3);
    g.endShape();
    // daun pintu (gelap), digeser sedikit ke arah kamera
    float x2 = x + sisi * 0.5;
    g.fill(10, 8, 6);
    g.beginShape(QUADS);
    g.vertex(x2, yAtas, zc - dz); g.vertex(x2, yAtas, zc + dz);
    g.vertex(x2, yBawah, zc + dz); g.vertex(x2, yBawah, zc - dz);
    g.endShape();
  }

  // ===================================================================
  //  BOLA CAHAYA (+ pintu lengkung di fase 1)
  // ===================================================================
  void drawOrb() {
    float cx = width * 0.5;
    float cy = height * 0.49;
    float Rd = height * ((fase == 1) ? 0.19 : 0.26) * (1 + 0.05 * kilat);   // radius cakram
    float Ri = Rd / 0.62;                                                    // setengah ukuran gambar

    imageMode(CORNER);
    tint(255, 255 * kilat);
    image(orbImg, cx - Ri, cy - Ri, Ri * 2, Ri * 2);
    noTint();
  }

  // ===================================================================
  //  GLITCH (fase 2): halo berundak, pintu, lempeng putih, serpihan.
  //  Berubah ~8x per beat (pakai hs(), BUKAN random(), supaya tidak
  //  mengganggu element lain yang memakai random()).
  // ===================================================================
  void drawGlitch(BeatClock t) {
    int s = t.eighthBeat;                                // seed berubah ~8x per beat
    float cx = width * 0.5 + (hs(s * 3 + 1) - 0.5) * 14;
    float cy = height * 0.5 + (hs(s * 3 + 2) - 0.5) * 8;
    float R  = height * 0.26;                            // radius dasar
    float fl = 0.8 + 0.2 * hs(s * 3 + 3);                // kilap

    noStroke();
    ellipseMode(CENTER);
    // halo berundak
    fill( 80,  52, 22, 220 * fl); ellipse(cx, cy, R * 2.70, R * 2.70);
    fill(215, 150, 60, 235 * fl); ellipse(cx, cy, R * 2.35, R * 2.35);
    fill(172, 168, 98, 255);      ellipse(cx, cy, R * 2.15, R * 2.15);
    fill(150, 168, 152, 255);     ellipse(cx, cy, R * 2.00, R * 2.00);

    // pintu lengkung gelap (agak ke kiri)
    float ax = cx - R * 0.18;
    fill(10, 8, 6);
    rectMode(CORNERS);
    rect(ax - R * 0.32, cy - R * 0.30, ax + R * 0.32, cy + R * 0.95);
    ellipse(ax, cy - R * 0.30, R * 0.64, R * 0.64);

    // lempeng putih miring + bayangan oranye di belakangnya
    float sk = (hs(s * 3 + 4) - 0.5) * R * 0.12;
    fill(120, 80, 30, 230);
    quad(cx - R * 0.02 + sk + 14, cy - R * 1.05, cx + R * 0.38 + sk + 14, cy - R * 1.10,
         cx + R * 0.26 + 14,      cy + R * 1.15, cx - R * 0.10 + 14,      cy + R * 1.12);
    fill(225, 246, 240);
    quad(cx - R * 0.02 + sk, cy - R * 1.05, cx + R * 0.38 + sk, cy - R * 1.10,
         cx + R * 0.26,      cy + R * 1.15, cx - R * 0.10,      cy + R * 1.12);

    // serpihan gelap di bagian atas
    for (int i = 0; i < 5; i++) {
      float bx = cx + (hs(s * 7 + i * 3 + 1) - 0.5) * R * 1.8;
      float by = cy - R * (0.95 + hs(s * 7 + i * 3 + 2) * 0.35);
      fill(50 + hs(i) * 40, 34, 14, 230);
      triangle(bx, by,
               bx + (hs(s * 7 + i * 3 + 3) - 0.3) * R * 0.7, by - R * 0.15,
               bx + R * 0.25, by + R * 0.20);
    }

    // kilap putih acak
    if (hs(s * 5 + 9) > 0.88) {
      fill(255, 70);
      rectMode(CORNER);
      rect(0, 0, width, height);
    }
  }

  // ===================================================================
  //  TEKS LIRIK: huruf demi huruf, meloncat lalu mendarat.
  //  Baris diambil dari ElLirik yang mulainya di [mulai, glitchMulai).
  //  Baris TERAKHIR tidak hilang; setelah glitchMulai huruf terakhirnya
  //  menumpuk 3 huruf per beat.
  // ===================================================================
  void drawText(BeatClock t, ElLirik l) {
    // cari baris terakhir adegan & baris yang sedang aktif
    int akhir = -1;
    for (int i = 0; i < l.lirik.length; i++) {
      if (l.lirikBeat[i] >= mulai && l.lirikBeat[i] < glitchMulai) akhir = i;
    }
    int idx = -1;
    for (int i = 0; i < l.lirik.length; i++) {
      float st = l.lirikBeat[i];
      if (st < mulai || st >= glitchMulai) continue;
      float en = (i == akhir) ? 999999 : st + l.durasiLirik[i];
      if (t.beatPos >= st && t.beatPos < en) { idx = i; break; }
    }
    if (idx < 0) return;

    String s = l.lirik[idx];
    float start = l.lirikBeat[idx];
    int n = s.length();
    if (n == 0) return;

    int extra = 0;
    if (idx == akhir && t.beatPos >= glitchMulai) {
      extra = min(70, (int) ((t.beatPos - glitchMulai) * 3.0));   // huruf ekstra menumpuk
    }
    int total = n + extra;

    float fs  = height * 0.046;     // ukuran huruf
    float adv = fs * 1.5;           // jarak antar huruf (renggang seperti di video)
    float x0  = width / 2.0 - (total - 1) * adv / 2.0;
    float y   = height * 0.5;

    textFont(font, fs);
    textAlign(CENTER, CENTER);

    for (int ki = 0; ki < total; ki++) {
      float x = x0 + ki * adv;
      if (x < -adv || x > width + adv) continue;

      // kapan huruf ini muncul
      float muncul = (ki < n) ? start + ki * 0.2 : glitchMulai + (ki - n) / 3.0;
      float u = t.beatPos - muncul;
      if (u < 0) continue;

      char c = (ki < n) ? s.charAt(ki) : s.charAt(n - 1);

      // loncat: mulai melayang di atas & miring & agak pudar, lalu mendarat
      float p  = constrain(u / 0.5, 0, 1);
      float e  = (1 - p) * (1 - p);
      float yo = -e * fs * 0.9;
      float an = e * 0.5 * ((ki % 2 == 0) ? 1 : -1);
      float sc = 1 + 0.25 * e;
      float al = 110 + 145 * p;
      color lyricColor = color(255);
      if (s.equals("抗う意味など") && ki < 2) {
        float redProgress = constrain(t.beatPos - 225, 0, 1);
        lyricColor = lerpColor(lyricColor, color(255, 0, 0), redProgress);
      }

      pushMatrix();
      translate(x, y + yo);
      rotate(an);
      scale(sc);
      fill(lyricColor, al);
      text(c, 0, 0);
      text(c, 0.9, 0);      // tebalkan sedikit
      popMatrix();
    }
  }

  // ===================================================================
  //  UTILITAS
  // ===================================================================
  // Tekstur bola: cakram putih-hijau berbintik, tepi oranye, halo oranye halus
  void buildOrb() {
    int n = 512;
    orbImg = createImage(n, n, ARGB);
    orbImg.loadPixels();
    float c = (n - 1) / 2.0;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        float d = dist(x, y, c, c) / c;     // 0 di pusat, 1 di tepi
        float r, gc, b, a;
        if (d < 0.62) {
          float q = d / 0.62;
          r  = lerp(232, 176, q);
          gc = lerp(240, 196, q);
          b  = lerp(230, 178, q);
          float rim = sst(0.80, 1.0, q);    // tepi cakram menguning-oranye
          r  = lerp(r,  255, rim);
          gc = lerp(gc, 196, rim);
          b  = lerp(b,   98, rim);
          float nz = random(-7, 7);         // bintik halus
          r += nz; gc += nz; b += nz;
          a = 255;
        } else {
          float q = constrain((d - 0.62) / 0.38, 0, 1);
          r  = 255;
          gc = 188 - 40 * q;
          b  = 90 - 40 * q;
          a  = 255 * pow(1 - q, 2.6);       // halo oranye memudar
        }
        orbImg.pixels[y * n + x] =
          (((int) constrain(a,  0, 255)) << 24) |
          (((int) constrain(r,  0, 255)) << 16) |
          (((int) constrain(gc, 0, 255)) << 8)  |
           ((int) constrain(b,  0, 255));
      }
    }
    orbImg.updatePixels();
  }

  // Hash 1D deterministik -> 0..1
  float hs(float n) {
    float v = sin(n * 12.9898 + 78.233) * 43758.5453;
    return v - floor(v);
  }

  // smoothstep: 0 sebelum a, 1 setelah b
  float sst(float a, float b, float x) {
    float k = constrain((x - a) / (b - a), 0, 1);
    return k * k * (3 - 2 * k);
  }
}