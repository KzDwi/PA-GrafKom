class VisualBeatObject {
  float x, y;
  float size;
  float targetSize;
  float baseSize; // Tambahkan ini
  
  VisualBeatObject(float x, float y, float baseSize) {
    this.x = x;
    this.y = y;
    this.baseSize = baseSize;
    this.size = baseSize;
    this.targetSize = baseSize;
  }
  
  void pulse() {
    targetSize = baseSize * 2.5; // Membesar 2.5x lipat saat beat
  }
  
  void update() {
    // Bola membesar/mengecil dengan halus
    size = lerp(size, targetSize, 0.3); 
    // Target size perlahan kembali ke ukuran awal
    targetSize = lerp(targetSize, baseSize, 0.1); 
  }
  
  void display() {
    pushMatrix();
    translate(x, y);
    fill(255, 100, 100);
    noStroke();
    // Menggunakan size (yang berubah-ubah)
    circle(0, 0, size); 
    popMatrix();
  }
}