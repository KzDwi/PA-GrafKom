// =====================================================================
//  el_KolomNegatif.pde   [ELEMENT 2D - KOLOM WARNA / NEGATIF]
//  Menggambar kolom selebar 1/4 layar yang loncat per beat (mirip kolom
//  emas kinetik) tetapi tanpa karakter. Warna bisa emas kecoklatan (default)
//  atau negatif dari latar (INVERT).
//
//  Pemakaian:
//    kolomNeg = new ElKolomNegatif();           // setup()
//    kolomNeg.show(clock, 312, 328);            // draw()
// =====================================================================
class ElKolomNegatif {
  float alphaMax = 210;                   // kepekatan kolom (0..255); 170 = agak transparan
  boolean negatif = false;                // true = warna negatif latar, false = emas kecoklatan
  color warna = color(142, 116, 44);      // warna emas kecoklatan (sama seperti kolom emas kinetik)
  boolean tepi = true;                    // true = gambar garis tepi tipis di sisi kolom

  void show(BeatClock t, float mulai, float akhir) {
    float b = t.beatPos;
    if (b < mulai || b >= akhir) return;

    int slot = ((int) floor(b - mulai)) % 4;    // slot kolom 0..3
    float cw = width / 4.0, x0 = slot * cw;     // lebar & posisi X kolom
    float punch = pow(1 - t.frac, 3);

    // fade in/out halus di awal & akhir
    float k = min(constrain((b - mulai) / 0.4, 0, 1), constrain((akhir - b) / 1.0, 0, 1));
    k = k * k * (3 - 2 * k);
    float a = min(235, alphaMax + 30 * punch) * k;   // alpha final

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
      rect(x0, 0, 2, height);              // garis tepi kiri
      rect(x0 + cw - 2, 0, 2, height);     // garis tepi kanan
    }
    hint(ENABLE_DEPTH_TEST);
  }
}