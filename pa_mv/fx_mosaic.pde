// =====================================================================
//  fx_mosaic.pde   [EFEK 2D]
//  Transisi "TV rabun": gambar pecah jadi kotak-kotak (mozaik) yang makin besar
//  + kotak berkedip/bergeser seperti sinyal jelek, lalu gelap. Bisa juga
//  kebalikannya (kotak besar -> jelas lagi). Dipanggil paling akhir sebelum UI.
//
//  Pemakaian:
//    mosaicFx = new FxMosaic();   // setup()
//    mosaicFx.show(clock, keluarMulai, keluarSelesai, masukMulai, masukSelesai);
//  Parameter waktu dalam beat pecahan:
//    keluar : gambar jelas -> kotak makin besar -> hitam
//    masuk  : dari kotak besar redup -> jelas
// =====================================================================
class FxMosaic {
  // ukuran blok (px) pada tiap tahap mozaik (makin besar = makin "rabun")
  float[] steps = { 12, 18, 28, 42, 64, 96, 140 };
  // p awal fase "masuk" (0 = jelas, 1 = hitam penuh)
  float masukDari = 0.82;

  FxMosaic() {}
  void reset() {}

  void show(BeatClock t, float outS, float outE, float inS, float inE) {
    float b = t.beatPos, p;
    if      (b >= outS && b < outE) p = (b - outS) / (outE - outS);        // fase keluar (0..1)
    else if (b >= outE && b < inS)  p = 1;                                  // fase hitam penuh
    else if (b >= inS  && b < inE)  p = masukDari * (1 - (b - inS) / (inE - inS));  // fase masuk (1..0)
    else return;
    apply(p, t);
  }

  // Terapkan efek mozaik. p: 0 = normal .. 1 = hitam penuh.
  void apply(float p, BeatClock t) {
    if (p <= 0.01) return;
    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);
    if (p >= 1) { fill(0); rect(0, 0, width, height); hint(ENABLE_DEPTH_TEST); return; }

    PImage snap = get();                       // snapshot layar saat ini
    snap.loadPixels();
    int d  = snap.pixelDensity;
    int pw = snap.pixelWidth;
    int ph = snap.pixelHeight;

    int si = constrain((int) (p * steps.length), 0, steps.length - 1);
    int bs = (int) steps[si];                  // ukuran blok yang dipakai
    float dark = constrain((p - 0.55) / 0.45, 0, 1);
    dark = dark * dark * (3 - 2 * dark);       // smoothstep: gelap muncul di akhir
    float noiseAmt = 14 + 40 * p;              // makin besar p, makin banyak noise

    for (int y = 0; y < height; y += bs) {
      // sebagian baris bergeser ke samping (kesan tracking error)
      float off = (random(1) < 0.12 * p) ? random(-1.5, 1.5) * bs : 0;
      for (int x = 0; x < width; x += bs) {
        float r = 0, g = 0, b = 0;
        // rata-rata 4 titik dalam tiap blok
        for (int k = 0; k < 4; k++) {
          int sx = constrain((int) ((x + bs * (0.25 + 0.5 * (k % 2))) * d), 0, pw - 1);
          int sy = constrain((int) ((y + bs * (0.25 + 0.5 * (k / 2))) * d), 0, ph - 1);
          color c = snap.pixels[sy * pw + sx];
          r += red(c); g += green(c); b += blue(c);
        }
        float n = random(-noiseAmt, noiseAmt);
        float m = 1 - dark;
        fill(constrain(r / 4 * m + n, 0, 255), constrain(g / 4 * m + n, 0, 255), constrain(b / 4 * m + n, 0, 255));
        rect(x + off, y, bs + 1, bs + 1);
      }
    }
    hint(ENABLE_DEPTH_TEST);
  }
}