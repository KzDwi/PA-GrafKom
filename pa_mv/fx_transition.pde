// =====================================================================
//  fx_transition.pde   [EFEK VISUAL]
//  Transisi 1: Layar flash menguning terang.
//  Transisi 2: Balok hitam menutup dari atas & bawah (Presser).
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
  int type = 0;  // 1: Flash Kuning, 2: Presser Hitam

  // Variabel untuk Glitch satu layar
  int glitchDuration = 2;   // lama glitch dalam FRAME (1-2 frame)
  int glitchFrames = 0;     // sisa frame glitch

  FxTransition() {}

  // Hentikan semua transisi (dipanggil saat RESTART)
  void reset() {
    state = 0;
    type = 0;
    flashAlpha = 0;
    barHeight = 0;
    glitchFrames = 0;
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

  // Panggil ini untuk transisi Presser Hitam (Baru)
  void triggerPresser() {
    state = 1;
    type = 2;
    barHeight = 0;
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

    hint(ENABLE_DEPTH_TEST);
  }
}
