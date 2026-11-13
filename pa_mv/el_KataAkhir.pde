// =====================================================================
//  el_KataAkhir.pde   [ELEMENT 2D - LAYAR HITAM + LIRIK HURUF DEMI HURUF]
//  Beat 290 -> 297 (setelah adegan spiral zoom, ditutup mosaik di 289-290).
//    - Layar hitam, distorsi putih SEDIKIT saja, datang dari tepi atas.
//    - Lirik beat 292 ("くるくるくりかえす") muncul HURUF DEMI HURUF,
//      tiap huruf meloncat lalu mendarat. Teks diambil dari ElLirik.
//    - Saat beat RED_AT seluruh teks LANGSUNG jadi merah.
//  Dihitung dari clock.beatPos -> aman pause/restart; pakai hash, bukan random().
//
//  Pemakaian:
//    kataAkhir = new ElKataAkhir(fontJepang);     // setup()
//    kataAkhir.show(clock, lirik);                // draw(), sesudah helpMe, sebelum UI
// =====================================================================
class ElKataAkhir {
  PFont font;                       // font untuk lirik
  final float START      = 290;     // layar hitam mulai
  final float TEXT_START = 292;     // huruf pertama muncul (= beat lirik)
  final float PER_HURUF  = 0.4;     // jarak antar huruf (beat)
  final float RED_AT     = 296;     // teks jadi merah
  final float END_BEAT   = 297;     // selesai

  ElKataAkhir(PFont font) { this.font = font; }

  void show(BeatClock t, ElLirik lk) {
    float b = t.beatPos;
    pushStyle();
    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);

    fill(0);
    rect(0, 0, width, height);

    drawTopDistortion(t, 0.55 * sst(START, START + 1.5, b));   // distorsi muncul pelan-pelan
    drawText(t, lk, b);

    hint(ENABLE_DEPTH_TEST);
    popStyle();
  }

  // ---------- distorsi putih tipis dari atas ----------
  // `k` = kekuatan distorsi (0..0.55)
  void drawTopDistortion(BeatClock t, float k) {
    if (k < 0.01) return;
    int st = ((int) (t.beatPos * 22)) % 400;
    float am = constrain(k / 0.4, 0, 1);        // alpha pengali
    noStroke();

    // cahaya tipis di tepi atas, berkedip
    fill(255, 12 * am);
    rect(0, 0, width, 20 + 50 * rnd(st, 0, 15));

    // garis horizontal, menumpuk di bagian atas layar
    int nl = (int) (3 + 9 * k);
    for (int i = 0; i < nl; i++) {
      float len = width * (0.05 + 0.5 * pow(rnd(st, i, 2), 2));
      float x   = rnd(st, i, 3) * width - len * 0.5;
      float y   = pow(rnd(st, i, 1), 2.6) * height * 0.55;
      fill(255, (60 + 150 * rnd(st, i, 4)) * am);
      rect(x, y, len, 1 + rnd(st, i, 5) * 2);
    }

    // goresan menetes dari tepi atas
    for (int i = 0; i < 4; i++) {
      if (rnd(st, i, 11) < 0.55) {
        float h = 30 + 230 * pow(rnd(st, i, 12), 1.5);
        fill(255, (40 + 90 * rnd(st, i, 14)) * am);
        rect(rnd(st, i, 13) * width, 0, 1 + rnd(st, i, 16), h);
      }
    }

    // bintik dekat atas
    int nd = (int) (24 * k);
    for (int i = 0; i < nd; i++) {
      fill(255, (50 + 150 * rnd(st, i, 21)) * am);
      rect(rnd(st, i, 22) * width, pow(rnd(st, i, 23), 2.2) * height * 0.5, 1 + rnd(st, i, 24) * 2, 1 + rnd(st, i, 25) * 2);
    }
  }

  // ---------- lirik: muncul huruf demi huruf, meloncat lalu mendarat ----------
  void drawText(BeatClock t, ElLirik lk, float b) {
    // cari baris lirik yang mulai tepat di TEXT_START
    String s = null;
    for (int i = 0; i < lk.lirik.length; i++) {
      if (lk.lirikBeat[i] == (int) TEXT_START) s = lk.lirik[i];
    }
    if (s == null) return;
    int n = s.length();
    if (n == 0) return;

    float fs  = height * 0.08;                       // ukuran huruf
    float adv = fs * 1.35;                           // jarak antar huruf
    float x0  = width / 2.0 - (n - 1) * adv / 2.0;   // posisi X huruf pertama
    float y   = height * 0.5;
    boolean merah = (b >= RED_AT);                   // true = warna merah

    textFont(font, fs);
    textAlign(CENTER, CENTER);

    for (int ki = 0; ki < n; ki++) {
      float u = b - (TEXT_START + ki * PER_HURUF);
      if (u < 0) continue;                           // huruf belum muncul

      float p  = constrain(u / 0.5, 0, 1);           // 0 = baru muncul, 1 = mendarat
      float e  = (1 - p) * (1 - p);                  // easing
      float yo = -e * fs * 0.9;                      // melayang di atas saat baru muncul
      float an = e * 0.5 * ((ki % 2 == 0) ? 1 : -1); // miring bergantian
      float sc = 1 + 0.25 * e;                       // sedikit lebih besar saat melayang
      float al = 110 + 145 * p;                      // alpha bertambah saat mendarat

      pushMatrix();
      translate(x0 + ki * adv, y + yo);
      rotate(an);
      scale(sc);
      if (merah) fill(215, 12, 12, al);
      else       fill(255, al);
      text(s.charAt(ki), 0, 0);
      text(s.charAt(ki), 0.9, 0);      // tebalkan sedikit
      popMatrix();
    }
  }

  // ---------- utilitas ----------
  float rnd(int st, int i, int salt) { return hs(st * 97 + i * 13 + salt * 1009); }

  // hash 1D deterministik -> 0..1
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