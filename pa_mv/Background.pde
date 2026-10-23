class Backroom {
  float z = 0;
  
  void display(int subBeat) {
    background(50);
    lights(); 
    
    // Rotasi akan bergoyang antara -0.2 dan 0.2 radian
    // Nilai berubah tiap sub-beat
    float rotasi = sin(subBeat * PI) * 0.2; 
    
    for (int i = 0; i < 10; i++) {
      pushMatrix();
      translate(width/2, height/2, -i * 200 + z);
      
      rotateZ(rotasi); // Menggunakan rotasi yang sudah dihitung
      
      noFill();
      // Beri warna stroke yang berbeda tiap kelipatan 4 sub-beat (1 birama)
      if (subBeat % 4 == 0) {
        stroke(255, 100, 100); // Warna merah tiap 1 bar
      } else {
        stroke(200, 200, 100); // Warna kuning
      }
      
      box(300); 
      popMatrix();
    }
    
    // Kecepatan lorong maju juga bisa disinkronkan
    // Misal: bergerak lebih cepat tiap 1 beat
    z += 5; 
    
    // Reset z agar tidak terlalu jauh ke depan (looping)
    if (z > 200) z = 0;
  }
}