// =====================================================================
//  el_SpiralZoom.pde   [ELEMENT 2D - ADEGAN SPIRAL FULL + KAMERA ZOOM]
//  Beat 264 -> 290. Memakai ulang spiral dari ElKinetik (kin.spiral), tapi sekarang
//  FULL layar (tanpa letterbox atas/bawah) dan tanpa huruf Jepang.
//    264 -> 272 : zoom KIRI-BAWAH spiral (sekitar tengah)        } langsung POTONG (cut),
//    272 -> 280 : zoom ATAS spiral, agak condong ke kanan        } tanpa animasi transisi
//    280 -> 290 : kembali ke posisi semula (spiral full, tanpa zoom)
//  Tiap segmen kamera diam di posisinya (merayap pelan hanya kalau DRIFT diisi > 0).
//  Spiral terus berputar (fasenya melanjutkan adegan kinetik: beat - 128).
//
//  spiralZoom = new ElSpiralZoom();               // setup()
//  spiralZoom.show(clock, kinetik);               // draw()  (beat 264-289)
//
//  Atur kamera lewat konstanta: T0..T3 (jadwal), ZA/FAX/FAY (zoom 1), ZB/FBX/FBY (zoom 2).
//  FAX/FAY = geseran titik fokus dari tengah layar, dalam pecahan lebar/tinggi layar
//  (x negatif = kiri, y positif = bawah).
// =====================================================================
class ElSpiralZoom {
  final float T0 = 264, T1 = 272, T2 = 280, T3 = 290;
  final float ZA  = 2.6,  FAX = -0.22, FAY =  0.18;   // zoom 1: kiri-bawah
  final float ZB  = 2.2,  FBX =  0.06, FBY = -0.24;   // zoom 2: atas, condong kanan
  final float DRIFT = 0;                              // dorongan zoom pelan selama tiap segmen (0 = kamera diam)
  final float GESER = 128;                            // fase spiral = beat - 128 (sama dgn kinetik ke-2)

  void show(BeatClock t, ElKinetik kin) {
    float b = t.beatPos;
    float W = width, H = height;

    // ---- hitung kamera: z = pembesaran, fx/fy = titik fokus (pecahan layar dari tengah) ----
    float z = 1, fx = 0, fy = 0;
    if (b < T1) {                                       // langsung zoom kiri-bawah (cut)
      float u = constrain((b - T0) / (T1 - T0), 0, 1);
      z = ZA + DRIFT * u;  fx = FAX;  fy = FAY;
    } else if (b < T2) {                                // langsung pindah zoom atas-kanan (cut)
      float u = constrain((b - T1) / (T2 - T1), 0, 1);
      z = ZB + DRIFT * u;  fx = FBX;  fy = FBY;
    }                                                   // selebihnya: posisi semula (z = 1)

    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);

    fill(kin.spDark);
    rect(0, 0, W, H);

    float punch = pow(1 - t.frac, 3);
    float cx = W * 0.5, cy = H * 0.5;
    float bs = b - GESER;

    pushMatrix();
    translate(cx, cy);
    scale(z * (1 + 0.015 * punch));
    translate(-(cx + fx * W), -(cy + fy * H));
    if (kin.imgSpiral.ada()) {
      float s = max(W / kin.imgSpiral.img.width, H / kin.imgSpiral.img.height);
      pushMatrix();
      translate(cx, cy);
      rotate(bs * 0.35);
      imageMode(CENTER);
      image(kin.imgSpiral.img, 0, 0, kin.imgSpiral.img.width * s * 2.2, kin.imgSpiral.img.height * s * 2.2);
      imageMode(CORNER);
      popMatrix();
    } else {
      kin.spiral(cx, cy, bs, punch);
    }
    popMatrix();

    hint(ENABLE_DEPTH_TEST);
  }

  // smoothstep: 0 sebelum a, 1 setelah b
  float sst(float a, float b, float x) {
    float k = constrain((x - a) / (b - a), 0, 1);
    return k * k * (3 - 2 * k);
  }
}
