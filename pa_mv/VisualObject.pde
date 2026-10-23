class VisualBeatObject {
  float x, y;
  float size;
  float targetSize;
  float baseSize;
  
  
  VisualBeatObject(float x, float y, float baseSize) {
    this.x = x;
    this.y = y;
    this.baseSize = baseSize;
    this.size = baseSize;
    this.targetSize = baseSize;
  }
  
  void pulse() {
    targetSize = baseSize * 2.5; 
  }
  
  void update() {
    size = lerp(size, targetSize, 0.3); 
    targetSize = lerp(targetSize, baseSize, 0.1); 
  }
  
  // Tambahkan parameter currentBeat
  void display(int currentBeat) {
    pushMatrix();
    translate(x, y);
    
    // Set warna dan hapus stroke
    fill(255, 100, 100);
    noStroke();
    
    // Menggunakan rectMode(CENTER) agar semua bentuk berpusat di (0,0)
    rectMode(CENTER); 
    
    // --- LOGIKA PERUBAHAN BENTUK BERDASARKAN BEAT ---
    if (currentBeat % 4 < 1) {
      // BEAT 0 - 7: Lingkaran
      circle(0, 0, size); 
      
    } else if (currentBeat % 4 < 2) {
      // BEAT 8 - 15: Persegi (Rectangle)
      rect(0, 0, size, size); 
      
    } else if (currentBeat % 4 < 3) {
      // BEAT 16 - 23: Segitiga (Triangle)
      // Menggunakan vertex agar presisi di tengah
      beginShape();
      vertex(0, -size/2);          // Titik atas
      vertex(size/2, size/2);      // Titik kanan bawah
      vertex(-size/2, size/2);     // Titik kiri bawah
      endShape(CLOSE);
      
    } else {
      rotate(radians(45)); 
      rect(0, 0, size, size);  
    }
    
    popMatrix();
  }
}