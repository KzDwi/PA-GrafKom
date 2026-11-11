// =====================================================================
//  fx_transition.pde   [EFEK VISUAL]
//  Transisi 1: Layar flash menguning terang.           -> trigger()
//  Transisi 2: Balok hitam menutup atas & bawah.       -> triggerPresser()
//  Transisi 3: Cahaya dari tengah sampai putih penuh.  -> triggerLight()
//  Semua digambar oleh show() (dipanggil sekali per frame di draw()).
// =====================================================================
class FxTransition {
  // Variabel untuk Flash
  float flashAlpha = 0;
  float rampUpSpeed = 15.0;  
  float rampDownSpeed = 4.0; 
  
  // Variabel untuk Presser Hitam
  float barHeight = 0; 
  float presserSpeed = 20.0; // Kecepatan balok hitam menutup/membuka
  
  int state = 0; // 0: IDLE, 1: CLOSING/RAMP_UP, 2: OPENING/RAMP_DOWN
  int type = 0;  // 1: Flash Kuning, 2: Presser Hitam, 3: Cahaya dari tengah

  // Variabel untuk Glitch satu layar
  int glitchDuration = 2;   // lama glitch dalam FRAME (1-2 frame)
  int glitchFrames = 0;     // sisa frame glitch

  // Variabel untuk Cahaya dari tengah (dihitung dari BEAT, bukan frame)
  float lightRise = 3.0;    // lama (beat) dari trigger sampai layar putih penuh
  float lightFade = 0.8;    // lama (beat) putih memudar sampai hilang
  float lightStart = 0;     // beatPos saat triggerLight() dipanggil
  PImage glowImg;           // tekstur gradasi radial (dibuat sekali)

  FxTransition() {
    buildGlow();
  }

  // Hentikan semua transisi (dipanggil saat RESTART)
  void reset() {
    state = 0;
    type = 0;
    flashAlpha = 0;
    barHeight = 0;
    glitchFrames = 0;
    lightStart = 0;
  }

  // Glitch satu layar, sangat singkat (glitchDuration frame)
  void triggerGlitch() {
    glitchFrames = glitchDuration;
  }

  // Dipanggil PALING AKHIR sebelum UI, supaya seluruh layar ikut ter-glitch
  void showGlitch() {
    if (glitchFrames <= 0) return;
    glitchFrames--;

    PImage snap = get();   // foto layar saat ini

    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);
    textureMode(NORMAL);
    tint(255);

    // 1. Layar dipotong jadi pita horizontal, sebagian digeser kiri/kanan
    float y = 0;
    while (y < height) {
      float h = min(random(8, 90), height - y);
      float off = (random(1) < 0.65) ? random(-140, 140) : 0;
      float v0 = y / height;
      float v1 = (y + h) / height;
      beginShape();
      texture(snap);
      vertex(off,         y,     0, v0);
      vertex(off + width, y,     1, v0);
      vertex(off + width, y + h, 1, v1);
      vertex(off,         y + h, 0, v1);
      endShape();
      y += h;
    }
    noTint();
    textureMode(IMAGE);

    // 2. Pita warna ala RGB-split + blok putih
    for (int i = 0; i < 5; i++) {
      if (random(1) < 0.5) fill(0, 255, 255, 90); else fill(255, 0, 80, 90);
      rect(0, random(height), width, random(4, 40));
    }
    fill(255, 230);
    rect(random(width), random(height), random(40, 260), random(3, 10));

    hint(ENABLE_DEPTH_TEST);
  }

  // Panggil ini untuk transisi Flash lama
  void trigger() {
    state = 1; 
    type = 1;
    flashAlpha = 0;
  }

  // Panggil ini untuk transisi Presser Hitam
  void triggerPresser() {
    state = 1;
    type = 2;
    barHeight = 0;
  }

  // Panggil ini untuk transisi Cahaya dari tengah.
  // Mulai dari beat saat dipanggil, putih penuh setelah lightRise beat,
  // lalu memudar selama lightFade beat.
  void triggerLight() {
    state = 1;
    type = 3;
    lightStart = clock.beatPos;
  }

  void show() {
    if (state == 0) return; // Jika tidak ada transisi aktif, lewati

    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);

    // ==========================================
    // TIPE 1: FLASH KUNING
    // ==========================================
    if (type == 1) {
      if (state == 1) {
        flashAlpha += rampUpSpeed;
        if (flashAlpha >= 255) {
          flashAlpha = 255;
          state = 2; 
        }
      } else if (state == 2) {
        flashAlpha -= rampDownSpeed;
        if (flashAlpha <= 0) {
          flashAlpha = 0;
          state = 0; 
        }
      }
      
      fill(255, 245, 250, flashAlpha); 
      rect(0, 0, width, height);
    }
    
    // ==========================================
    // TIPE 2: PRESSER HITAM (Dari atas & bawah)
    // ==========================================
    else if (type == 2) {
      if (state == 1) { // Menutup ke tengah
        barHeight += presserSpeed;
        if (barHeight >= height / 2) {
          barHeight = height / 2; // Rapat di tengah
          state = 2; // Ganti fase jadi membuka kembali
        }
      } else if (state == 2) { // Membuka kembali
        barHeight -= presserSpeed;
        if (barHeight <= 0) {
          barHeight = 0;
          state = 0; 
        }
      }
      
      fill(0); // Warna hitam pekat
      
      // Gambar balok atas
      rect(0, 0, width, barHeight);
      
      // Gambar balok bawah (mulai dari tinggi layar dikurangi ketebalan balok)
      rect(0, height - barHeight, width, barHeight);
    }

    // ==========================================
    // TIPE 3: CAHAYA DARI TENGAH LAYAR
    // ==========================================
    else if (type == 3) {
      drawLight();
    }

    hint(ENABLE_DEPTH_TEST);
  }

  // Titik cahaya kecil di tengah, makin besar (pelan di awal, melesat di akhir)
  // sampai layar putih penuh, lalu memudar. Dihitung dari clock.beatPos, jadi
  // ikut berhenti saat lagu di-pause.
  void drawLight() {
    float b = clock.beatPos - lightStart;          // beat sejak trigger
    if (b < 0 || b >= lightRise + lightFade) {     // selesai (atau lagu di-restart mundur)
      state = 0;
      return;
    }

    float cx = width / 2.0;
    float cy = height / 2.0;
    float diag = dist(0, 0, width, height);

    float R, haloA, coreA, washA;
    if (b < lightRise) {
      // fase mendekat: p 0 -> 1
      float p = b / lightRise;
      float e = p * p * p;                         // pelan dulu, lalu tiba-tiba melesat
      R     = lerp(40, diag * 1.2, e);             // radius halo (px)
      haloA = 255 * constrain(p * 4, 0, 1);
      coreA = 255 * constrain(p * 3, 0, 1);
      washA = 255 * sstep(0.6, 1.0, p);            // putih penuh menjelang puncak
    } else {
      // fase memudar: putih -> hilang
      float f = 1 - (b - lightRise) / lightFade;
      R     = diag * 1.2;
      haloA = 255 * f;
      coreA = 255 * f;
      washA = 255 * f;
    }

    pushStyle();

    // halo besar
    tint(255, haloA);
    image(glowImg, cx - R, cy - R, R * 2, R * 2);

    // inti terang di tengah
    float r2 = R * 0.35;
    tint(255, coreA);
    image(glowImg, cx - r2, cy - r2, r2 * 2, r2 * 2);
    noTint();

    // lapisan putih penuh
    if (washA > 0) {
      fill(255, 250, 240, washA);
      rect(0, 0, width, height);
    }

    popStyle();
  }

  // Bikin tekstur gradasi radial putih-hangat: terang di pusat, transparan di tepi
  void buildGlow() {
    int n = 256;
    glowImg = createImage(n, n, ARGB);
    glowImg.loadPixels();
    float c = (n - 1) / 2.0;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        float d = dist(x, y, c, c) / c;                      // 0 di pusat, 1 di tepi
        int a = (int)(pow(constrain(1 - d, 0, 1), 2.0) * 255);
        glowImg.pixels[y * n + x] = (a << 24) | (255 << 16) | (250 << 8) | 240;
      }
    }
    glowImg.updatePixels();
  }

  // smoothstep sederhana: 0 sebelum a, 1 setelah b, halus di antaranya
  float sstep(float a, float b, float x) {
    float k = constrain((x - a) / (b - a), 0, 1);
    return k * k * (3 - 2 * k);
  }
}
