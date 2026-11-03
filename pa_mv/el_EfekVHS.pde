// =====================================================================
//  el_EfekVHS.pde   [ELEMENT 2D - OVERLAY]
//  Menambahkan efek pita kaset video retro (VCR).
//  Berisi scanlines, noise pita, vignette, dan glitch saat beat baru.
// =====================================================================
class ElEfekVHS {
  
  ElEfekVHS() {}

  void show(BeatClock t) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    
    // 1. Scanlines (Garis horizontal tipis ala TV tabung)
    stroke(0, 50); // Hitam transparan
    strokeWeight(2);
    for (int y = 0; y < height; y += 4) {
      line(0, y, width, y);
    }
    
    // 2. Grain / Noise debu pita kaset
    noStroke();
    fill(255, random(10, 25));
    for (int i = 0; i < 150; i++) {
      float rx = random(width);
      float ry = random(height);
      rect(rx, ry, random(2, 6), random(1, 3));
    }
    
    // 3. Glitch / Tracking Error (Muncul lebih sering/tebal saat awal beat)
    if (t.newBeat || random(1) < 0.05) {
      fill(255, random(10, 40));
      float glitchY = random(height);
      float glitchH = random(10, 60);
      rect(0, glitchY, width, glitchH);
    }
    
    // 4. Vignette (Bayangan gelap di pinggiran layar)
    noFill();
    stroke(0, 150);
    strokeWeight(120);
    rectMode(CORNER);
    rect(-60, -60, width + 120, height + 120);
    
    // 5. Teks UI VCR Retro (Pojok kiri atas)
    fill(255, 200);
    textAlign(LEFT, TOP);
    textSize(28);
    // Tulisan PLAY berkedip setiap 1/2 beat
    if (t.subBeat % 2 == 0) {
      text("PLAY ►", 40, 40);
    }
    // Waktu palsu berjalan sesuai beat
    textSize(22);
    text("SP  0:00:" + nf(t.beat, 2), 40, 75);

    hint(ENABLE_DEPTH_TEST);
  }
}
