// =====================================================================
//  el_SpiralZoom.pde   [ELEMENT 2D - ADEGAN SPIRAL FULL + KAMERA ZOOM]
//  Beat 264 -> 290. Memakai ulang spiral dari ElKinetik (kin.spiral),
//  tetapi kali ini FULL layar (tanpa letterbox atas/bawah) dan tanpa huruf Jepang.
//    264 -> 272 : zoom kiri-bawah spiral          } langsung POTONG (cut),
//    272 -> 280 : zoom atas, condong ke kanan     } tanpa transisi
//    280 -> 290 : kembali ke posisi semula
//  Tiap segmen kamera diam di posisinya (drift hanya aktif kalau DRIFT > 0).
//  Spiral terus berputar melanjutkan fase adegan kinetik (beat - 128).
//  Tiap segmen menampilkan MAX_CLONES clone yang bergeser tiap beat.
//
//  Pemakaian:
//    spiralZoom = new ElSpiralZoom();       // di setup()
//    spiralZoom.show(clock, kinetik);       // di draw(), saat beat 264-289
// =====================================================================
class ElSpiralZoom {
  // ---- jadwal segmen (satuan beat) ----
  final float T0 = 264, T1 = 272, T2 = 280, T3 = 290;

  // ---- kamera segmen 1: zoom kiri-bawah ----
  final float ZA  = 2.6,  FAX = -0.22, FAY =  0.18;   // ZA=zoom, FAX/FAY=geser fokus (pecahan layar)
  // ---- kamera segmen 2: zoom atas, condong kanan ----
  final float ZB  = 2.2,  FBX =  0.06, FBY = -0.24;   // ZB=zoom, FBX/FBY=geser fokus

  final float DRIFT = 0;                              // dorongan zoom pelan selama segmen (0 = kamera diam)
  final float GESER = 128;                            // fase spiral = beat - GESER (sinkron dengan kinetik ke-2)

  final int   MAX_CLONES = 5;                         // jumlah clone yang digambar
  final float CLONE_END_Y       = 0;                  // posisi tengah baris clone segmen 1 (pecahan tinggi layar)
  final float CLONE_T1_CENTER_Y = 0.85;               // posisi tengah baris clone segmen 2
  final float CLONE_T2_CENTER_Y = 0.5;                // posisi tengah baris clone segmen 3
  final float CLONE_HEIGHT      = 1.5;                // tinggi clone segmen 1-2 (pecahan tinggi layar)
  final float CLONE_T2_HEIGHT   = 0.8;                // tinggi clone segmen 3
  final float CLONE_SLIDE_BEATS = 0.3;                // lama animasi geser antar beat (beat)
  PImage[] clonePoses = new PImage[MAX_CLONES];       // gambar pose untuk tiap clone

  ElSpiralZoom() {
    for (int i = 0; i < MAX_CLONES; i++) {
      // pose ke-4 pakai file khusus "pose4f.png", sisanya "pose1..5.png"
      String poseFile = i == 3 ? "assets/pose4f.png" : "assets/pose" + (i + 1) + ".png";
      clonePoses[i] = loadImage(poseFile);
    }
  }

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

    float punch = pow(1 - t.frac, 3);                   // kilatan tiap beat (memudar dalam 1 beat)
    float cx = W * 0.5, cy = H * 0.5;
    float bs = b - GESER;                               // fase spiral

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
      kin.spiral(cx, cy, bs, punch);                    // fallback: gambar spiral prosedural
    }
    popMatrix();

    // ---- baris clone (5 pose bergeser tiap beat) ----
    if (b >= T0 && b < T3) {
      float phaseStart = b >= T2 ? T2 : (b >= T1 ? T1 : T0);
      float centerY = b >= T2 ? CLONE_T2_CENTER_Y
                    : (b >= T1 ? CLONE_T1_CENTER_Y : CLONE_END_Y);
      float cloneHeight = b >= T2 ? CLONE_T2_HEIGHT : CLONE_HEIGHT;
      float elapsed = b - phaseStart;
      int beatStep = (int) floor(elapsed);              // beat ke berapa dalam segmen
      float beatProgress = elapsed - beatStep;
      float slide = sst(0, CLONE_SLIDE_BEATS, beatProgress);
      float spacing = b >= T2 ? W / MAX_CLONES : W / (MAX_CLONES - 2.5);
      float firstX = b >= T2 ? spacing * 0.5 : W * 0.5 - (MAX_CLONES - 1) * spacing * 0.5;
      imageMode(CENTER);
      for (int i = 0; i < MAX_CLONES; i++) {
        int poseIndex = (i + beatStep) % MAX_CLONES;
        PImage pose = clonePoses[poseIndex];
        if (pose != null) {
          float poseHeight = H * cloneHeight;
          float poseWidth = pose.width * poseHeight / pose.height;
          if (b >= T2 && poseWidth > spacing * 0.9) {
            float fitScale = spacing * 1.8 / poseWidth;
            poseWidth *= fitScale;
            poseHeight *= fitScale;
          }
          float x = firstX + i * spacing - slide * spacing;
          float y = H * centerY;
          image(pose, x, y, poseWidth, poseHeight);
          if (i == 0) {
            // clone pembungkus: tampil di ujung kanan saat slide untuk efek loop mulus
            image(pose, firstX + (MAX_CLONES - 1) * spacing + spacing * (1 - slide),
                  y, poseWidth, poseHeight);
          }
        }
      }
      imageMode(CORNER);
    }

    hint(ENABLE_DEPTH_TEST);
  }

  // smoothstep: 0 sebelum a, 1 setelah b, halus di antaranya
  float sst(float a, float b, float x) {
    float k = constrain((x - a) / (b - a), 0, 1);
    return k * k * (3 - 2 * k);
  }
}