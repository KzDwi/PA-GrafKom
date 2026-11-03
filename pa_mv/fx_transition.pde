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

  FxTransition() {}

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
