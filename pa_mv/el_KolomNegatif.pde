// =====================================================================
//  kolomNeg = new ElKolomNegatif();           // setup()
//  kolomNeg.show(clock, 312, 328);            // draw()
//  Pengaturan: alphaMax (0..255, default 95), tepi (garis tipis di sisi kolom)
// =====================================================================
class ElKolomNegatif {
  float alphaMax = 210;                   // kepekatan kolom (0..255); 255 = pekat penuh, sedikit transparan di ~170
  boolean negatif = false;                // true = warna negatif latar, false = emas kecoklatan
  color warna = color(142, 116, 44);      // emas kecoklatan (sama seperti kolom emas kinetik)
  boolean tepi = true;

  void show(BeatClock t, float mulai, float akhir) {
    float b = t.beatPos;
    if (b < mulai || b >= akhir) return;

    int slot = ((int) floor(b - mulai)) % 4;
    float cw = width / 4.0, x0 = slot * cw;
    float punch = pow(1 - t.frac, 3);

    float k = min(constrain((b - mulai) / 0.4, 0, 1), constrain((akhir - b) / 1.0, 0, 1));
    k = k * k * (3 - 2 * k);
    float a = min(235, alphaMax + 30 * punch) * k;

    hint(DISABLE_DEPTH_TEST);
    noLights();
    if (negatif) {
      PImage neg = get((int) x0, 0, (int) cw, height);
      neg.filter(INVERT);
      imageMode(CORNER);
      tint(255, a);
      image(neg, x0, 0, cw, height);
      noTint();
    } else {
      noStroke();
      fill(red(warna), green(warna), blue(warna), a);
      rect(x0, 0, cw, height);
    }

    if (tepi) {
      noStroke();
      fill(red(warna) + 60, green(warna) + 60, blue(warna) + 40, 60 * k);
      rect(x0, 0, 2, height);
      rect(x0 + cw - 2, 0, 2, height);
    }
    hint(ENABLE_DEPTH_TEST);
  }
}
