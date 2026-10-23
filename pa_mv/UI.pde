class PolyrhythmUI {
  float boxX, boxY;
  float boxW, boxH;
  
  // Variabel untuk menyimpan status beat terakhir di tiap layer
  int lastLayer1 = -1;
  int lastLayer2 = -1;
  int lastLayer3 = -1;
  int lastLayer4 = -1;
  
  // Ukuran/Brightness yang berubah tiap beat (untuk animasi)
  float b1 = 0, b2 = 0, b3 = 0, b4 = 0;

  PolyrhythmUI(float x, float y, float w, float h) {
    this.boxX = x;
    this.boxY = y;
    this.boxW = w;
    this.boxH = h;
  }

  void update(int beat, int subBeat, int quarterBeat, int eighthBeat) {
    // Jika beat berubah, picu animasi membesar
    if (beat != lastLayer1) { b1 = 1.0; lastLayer1 = beat; }
    if (subBeat != lastLayer2) { b2 = 1.0; lastLayer2 = subBeat; }
    if (quarterBeat != lastLayer3) { b3 = 1.0; lastLayer3 = quarterBeat; }
    if (eighthBeat != lastLayer4) { b4 = 1.0; lastLayer4 = eighthBeat; }

    // Animasi mengecil kembali secara halus (fade out)
    b1 = lerp(b1, 0, 0.1);
    b2 = lerp(b2, 0, 0.1);
    b3 = lerp(b3, 0, 0.1);
    b4 = lerp(b4, 0, 0.1);
  }

  void display() {
    pushMatrix();
    hint(DISABLE_DEPTH_TEST); // Pastikan UI tidak terpengaruh 3D
    translate(boxX, boxY);
    
    // 1. Gambar Kotak Latar Belakang UI
    rectMode(CORNER);
    fill(0, 150); // Hitam transparan
    stroke(255, 100);
    strokeWeight(2);
    rect(0, 0, boxW, boxH, 10); // Kotak dengan sudut membulat
    
    // 2. Layer 1 (1/1 Beat) - Bola Besar di Kiri
    noStroke();
    fill(255, 100, 100, 100 + (b1 * 155)); // Merah
    circle(30, boxH/2, 20 + (b1 * 30));
    
    // 3. Layer 2 (1/2 Beat) - Kotak di Tengah
    fill(100, 255, 255, 100 + (b2 * 155)); // Cyan
    rect(60, boxH/2 - 10, 20 + (b2 * 20), 20 + (b2 * 20));
    
    // 4. Layer 3 (1/4 Beat) - Garis Vertikal
    stroke(100, 255, 100, 100 + (b3 * 155)); // Hijau
    strokeWeight(3);
    float lineHeight = 40 + (b3 * 30);
    line(110, boxH/2 - lineHeight/2, 110, boxH/2 + lineHeight/2);
    
    // 5. Layer 4 (1/8 Beat) - Partikel/Noise di Kanan
    noStroke();
    fill(255, 100, 255, 100 + (b4 * 155)); // Magenta
    // Membuat 3 partikel kecil yang berdenyut
    for (int i = 0; i < 3; i++) {
      float offsetY = sin(frameCount * 0.1 + i) * 10;
      float sizeP = 5 + (b4 * 10);
      circle(140 + i * 15, boxH/2 + offsetY, sizeP);
    }
    
    // Teks Label kecil di dalam UI
    fill(255);
    textSize(10);
    textAlign(LEFT, TOP);
    text("POLYRHYTHM", 5, 5);
    
    popMatrix();
    hint(ENABLE_DEPTH_TEST);
  }
}

class GUIButton {
  float x, y, w, h;
  String label;
  color baseColor;
  color hoverColor;
  boolean isHovered = false;
  
  GUIButton(float x, float y, float w, float h, String label, color baseColor) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.baseColor = baseColor;
    this.hoverColor = lerpColor(baseColor, color(255), 0.3); // Warna lebih terang saat hover
  }
  
  // Cek apakah mouse ada di atas tombol
  void updateHover(float mx, float my) {
    isHovered = (mx >= x && mx <= x + w && my >= y && my <= y + h);
  }
  
  // Cek apakah tombol diklik
  boolean isClicked(float mx, float my) {
    return (mx >= x && mx <= x + w && my >= y && my <= y + h);
  }
  
  void display() {
    pushMatrix();
    hint(DISABLE_DEPTH_TEST); // Pastikan tidak terpengaruh 3D
    rectMode(CORNER);
    
    // Gambar kotak tombol
    if (isHovered) {
      fill(hoverColor);
      stroke(255); // Border putih saat hover
    } else {
      fill(baseColor);
      noStroke();
    }
    strokeWeight(2);
    rect(x, y, w, h, 8); // Sudut membulat
    
    // Teks tombol
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text(label, x + w/2, y + h/2);
    
    popMatrix();
    hint(ENABLE_DEPTH_TEST);
  }
}