// =====================================================================
//  el_HelpMe.pde   [ELEMENT 2D - ZOOM PINTU + GLITCH + TEKS BASE64]
//  Adegan beat 227.5-231:
//    - Foto layar di-zoom ke arah pintu (zoom blur berlapis)
//    - Layar hitam + distorsi putih (noise, garis, blok, goresan)
//    - Teks Base64 "SGVscCBNZQ==" (= "Help Me") muncul huruf demi huruf
//      dengan sebagian huruf berubah merah, lalu memudar menjelang transisi
//  Dihitung dari clock.beatPos -> aman pause/restart.
//
//  Pemakaian:
//    helpMe = new ElHelpMe();       // setup()
//    helpMe.show(clock);            // draw(), PALING AKHIR sebelum UI
// =====================================================================
class ElHelpMe {
  // ---- JADWAL (beat) ----
  final float ZOOM_START  = 227.5;   // mulai zoom ke pintu
  final float BLACK_START = 228.0;   // layar jadi hitam penuh
  final float TEXT_START  = 229.5;   // huruf pertama teks muncul
  final float TEXT_FADE   = 0.8;     // lama kemunculan teks (beat)
  final float FADE_START  = 230.0;   // distorsi mulai memudar
  final float END_BEAT    = 231.0;   // selesai
  final float ZOOM_MAX    = 16;      // pembesaran maksimum saat zoom
  final float FOCUS_X     = 0.50;    // titik fokus zoom (pecahan lebar layar)
  final float FOCUS_Y     = 0.53;    // titik fokus zoom (pecahan tinggi layar)
  final int   RED_MIN     = 3;       // jumlah minimum huruf merah
  final int   RED_MAX     = 5;       // jumlah maksimum huruf merah

  String kode;       // teks Base64 dari "Help Me" -> "SGVscCBNZQ=="
  PFont font;        // font monospace untuk teks Base64
  PImage snap = null;   // snapshot layar (diambil sekali di awal zoom)
  float am = 1;      // pengali alpha garis distorsi (1 = penuh, 0 = hilang)

  ElHelpMe() {
    kode = java.util.Base64.getEncoder().encodeToString(
             "Help Me".getBytes(java.nio.charset.StandardCharsets.UTF_8));
    font = createFont("Monospaced.bold", 96);
  }

  void show(BeatClock t) {
    float b = t.beatPos;
    if (b < ZOOM_START) { snap = null; return; }   // belum waktunya / lagu restart
    if (b >= END_BEAT) return;

    pushStyle();
    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);

    if (b < BLACK_START) {
      if (snap == null) snap = get();               // foto layar sekali saat zoom mulai
      drawZoom(t, (b - ZOOM_START) / (BLACK_START - ZOOM_START));
    } else {
      fill(0);
      rect(0, 0, width, height);
      float v = (b - BLACK_START) / (END_BEAT - BLACK_START);        // 0..1 progres fase hitam
      am = 1 - sst(FADE_START, END_BEAT, b);                         // garis memudar menjelang transisi
      float k = (0.55 + 0.45 * v + 0.20 * pow(1 - t.frac, 3)) * am;  // kerapatan distorsi
      drawDistortion(t, k);
      if (b >= TEXT_START) drawText(t, b);
    }

    hint(ENABLE_DEPTH_TEST);
    popStyle();
  }

  // ===================================================================
  //  ZOOM ke pintu: foto layar diperbesar dari titik pintu, makin lama makin cepat.
  //  Dua lapis bayangan lebih besar (transparan) memberi kesan zoom blur.
  //  `u` = progres 0..1.
  // ===================================================================
  void drawZoom(BeatClock t, float u) {
    u = constrain(u, 0, 1);
    am = 1;
    float fx = width * FOCUS_X;     // x titik fokus
    float fy = height * FOCUS_Y;    // y titik fokus

    fill(0);
    rect(0, 0, width, height);

    zoomLayer(pow(u, 2.4), 255, fx, fy);                        // lapis utama
    zoomLayer(pow(min(1, u + 0.08), 2.4), 85, fx, fy);          // bayangan 1
    zoomLayer(pow(min(1, u + 0.16), 2.4), 45, fx, fy);          // bayangan 2

    // makin dekat makin gelap (pintu menelan layar)
    noStroke();
    fill(0, 255 * sst(0.65, 1.0, u));
    rect(0, 0, width, height);

    // distorsi mulai merayap di ujung zoom
    float k = 0.30 * sst(0.45, 1.0, u);
    if (k > 0.01) drawDistortion(t, k);
  }

  // Satu lapis foto. `e` = progres zoom (0..1, sudah di-ease),
  // `alpha` = transparansi, `fx/fy` = titik fokus awal.
  void zoomLayer(float e, float alpha, float fx, float fy) {
    float s  = pow(ZOOM_MAX, e);
    float px = lerp(fx, width * 0.5, e);     // titik fokus perlahan bergeser ke tengah
    float py = lerp(fy, height * 0.5, e);
    pushMatrix();
    translate(px, py);
    rotate(0.05 * e);                        // sedikit miring
    scale(s);
    translate(-fx, -fy);
    imageMode(CORNER);
    tint(255, alpha);
    image(snap, 0, 0, width, height);
    noTint();
    popMatrix();
  }

  // ===================================================================
  //  DISTORSI PUTIH di atas hitam. `k` = kerapatan (0..~1.2).
  //  Berubah ~22x per beat (hampir tiap frame).
  // ===================================================================
  void drawDistortion(BeatClock t, float k) {
    int st = ((int) (t.beatPos * 22)) % 400;    // seed berubah cepat seiring beat
    noStroke();
    rectMode(CORNER);

    // 1. bintik / noise
    int nd = (int) (240 * k);
    for (int i = 0; i < nd; i++) {
      fw(50 + 170 * rnd(st, i, 1));
      rect(rnd(st, i, 2) * width, rnd(st, i, 3) * height, 1 + rnd(st, i, 4) * 3, 1 + rnd(st, i, 5) * 2);
    }

    // 2. garis horizontal acak
    int nl = (int) (10 + 34 * k);
    for (int i = 0; i < nl; i++) {
      float len = width * (0.06 + 0.94 * pow(rnd(st, i, 11), 2));
      float x   = rnd(st, i, 12) * width - len * 0.5;
      float y   = rnd(st, i, 13) * height;
      float th  = (rnd(st, i, 14) < 0.15) ? 3 + rnd(st, i, 15) * 6 : 1 + rnd(st, i, 16) * 1.5;
      fw(80 + 175 * rnd(st, i, 17));
      rect(x, y, len, th);
    }

    // 3. balok retakan lebar (tracking error)
    int nb = 1 + (int) (3 * k);
    for (int i = 0; i < nb; i++) {
      float y = rnd(st, i, 21) * height;
      float h = 8 + rnd(st, i, 22) * 50;
      fw(18 + 45 * rnd(st, i, 23));
      rect(0, y, width, h);
      fw(70 + 120 * rnd(st, i, 24));
      rect(rnd(st, i, 25) * width * 0.5, y + h * 0.5, width * (0.2 + 0.6 * rnd(st, i, 26)), 2);
    }

    // 4. blok datamosh kecil
    for (int i = 0; i < 5; i++) {
      if (rnd(st, i, 31) < 0.5) {
        fw(25 + 70 * rnd(st, i, 32));
        rect(rnd(st, i, 33) * width, rnd(st, i, 34) * height, 40 + rnd(st, i, 35) * 260, 6 + rnd(st, i, 36) * 34);
      }
    }

    // 5. goresan vertikal
    for (int i = 0; i < 6; i++) {
      if (rnd(st, i, 41) < 0.5) {
        float h = height * (0.25 + 0.75 * rnd(st, i, 42));
        fw(45 + 90 * rnd(st, i, 43));
        rect(rnd(st, i, 44) * width, rnd(st, i, 45) * (height - h), 1 + rnd(st, i, 46), h);
      }
    }

    // 6. pita tracking yang turun terus
    float ty = ((t.beatPos * 1.7) % 1.0) * (height + 160) - 80;
    fw(16);
    rect(0, ty, width, 70);
    fw(34);
    rect(0, ty + 22, width, 22);
    fw(120);
    rect(0, ty + 30 + (rnd(st, 0, 47) - 0.5) * 6, width, 2);

    // 7. kilap putih tipis (jarang)
    if (rnd(st, 0, 51) < 0.07 * k) {
      fw(22 + 28 * rnd(st, 1, 51));
      rect(0, 0, width, height);
    }
  }

  // ===================================================================
  //  TEKS BASE64: huruf menyala satu-satu dari distorsi, lalu bergetar.
  // ===================================================================
  void drawText(BeatClock t, float b) {
    float p  = sst(TEXT_START, TEXT_START + TEXT_FADE, b);                 // 0..1 kemunculan teks
    float tp = constrain((b - TEXT_START) / (END_BEAT - TEXT_START), 0, 1); // 0..1 sampai selesai
    int st   = ((int) (b * 22)) % 400;
    int n    = kode.length();

    float fs = height * 0.115;      // ukuran huruf
    textFont(font, fs);
    textAlign(CENTER, CENTER);
    float cw = textWidth("0");      // lebar satu huruf (monospace)
    float cx = width * 0.5;
    float cy = height * 0.5;
    float x0 = cx - (n - 1) * cw * 0.5;

    // kilatan distorsi yang "membentuk" teks (makin habis saat teks jelas)
    int nf = (int) (34 * (1 - p));
    noStroke();
    for (int i = 0; i < nf; i++) {
      fw(110 + 120 * rnd(st, i, 71));
      rect(cx + (rnd(st, i, 72) - 0.5) * cw * n * 1.3, cy + (rnd(st, i, 73) - 0.5) * fs * 1.3,
           10 + rnd(st, i, 74) * 120, 1 + rnd(st, i, 75) * 4);
    }

    // sentakan horizontal sesekali
    float jerk = (rnd(st, 0, 76) < 0.12) ? (rnd(st, 1, 76) - 0.5) * 60 : 0;
    float creep = 1 + 0.06 * tp;                    // merayap membesar pelan

    // pilih 3-5 huruf yang jadi merah (diacak ulang tiap subBeat)
    boolean[] merah = new boolean[n];
    int sb = ((int) (b * 2)) % 400;
    int target = RED_MIN + (int) (rnd(sb, 0, 91) * (RED_MAX - RED_MIN + 1));
    target = constrain(target, 0, n);
    int got = 0;
    for (int tr = 0; tr < 80 && got < target; tr++) {
      int idx = constrain((int) (rnd(sb, tr + 1, 90) * n), 0, n - 1);
      if (!merah[idx]) { merah[idx] = true; got++; }
    }

    pushMatrix();
    translate(cx + jerk, cy);
    scale(creep);
    translate(-cx, -cy);
    for (int i = 0; i < n; i++) {
      if (rnd(st, i, 60) >= p) continue;            // huruf belum menyala
      float a  = 255 * (0.25 + 0.75 * p);
      float sh = 1 - 0.6 * p;                       // getaran mengecil saat teks jelas
      float x  = x0 + i * cw + (rnd(st, i, 61) - 0.5) * 14 * sh;
      float y  = cy + (rnd(st, i, 62) - 0.5) * 10 * sh;
      char  c  = kode.charAt(i);
      float rr = merah[i] ? 215 : 255;              // huruf terpilih = merah darah
      float gg = merah[i] ? 12  : 255;
      float bb = merah[i] ? 12  : 255;
      fill(rr, gg, bb, a * 0.30);  text(c, x - 5, y);   // bayangan kiri-kanan
      fill(rr, gg, bb, a * 0.30);  text(c, x + 5, y);
      fill(rr, gg, bb, a);         text(c, x, y);
    }
    popMatrix();

    // bar hitam & garis putih memotong teks (kesan sinyal putus)
    int nbk = (int) ceil((3 + 4 * (1 - 0.5 * p)) * am);
    for (int i = 0; i < nbk; i++) {
      float by = cy + (rnd(st, i, 81) - 0.5) * fs * 1.5;
      fill(0, 210 * am);
      rect(rnd(st, i, 82) * width * 0.8, by, width * (0.08 + 0.45 * rnd(st, i, 83)), 2 + rnd(st, i, 84) * 9);
    }
    int nwl = (int) ceil(6 * am);
    for (int i = 0; i < nwl; i++) {
      fw(70 + 150 * rnd(st, i, 85));
      rect(rnd(st, i, 86) * width * 0.7, cy + (rnd(st, i, 87) - 0.5) * fs * 1.6,
           width * (0.1 + 0.4 * rnd(st, i, 88)), 1 + rnd(st, i, 89) * 2);
    }
  }

  // isi putih dengan alpha dikali am (supaya garis bisa memudar)
  void fw(float a) { fill(255, a * am); }

  // ===================================================================
  //  UTILITAS
  // ===================================================================
  // angka acak tetap (0..1) dari (langkah, indeks, garam) -> sama setiap diputar
  float rnd(int st, int i, int salt) {
    return hs(st * 97 + i * 13 + salt * 1009);
  }

  // hash 1D deterministik -> nilai 0..1
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