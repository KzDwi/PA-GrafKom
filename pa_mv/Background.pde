class Backroom {
  float z = 0;
  
  // Tambahkan parameter int currentBeat
  void display(int subBeat, int currentBeat) {
    
    // Kita gunakan modulo (%) agar background terus berulang 1-2-3-4
    int bgChoice = 0; 
    
    if (currentBeat >= 22 && currentBeat <= 23){
      bgChoice = 0; // Background 1: Gelap, Kuning
    }
    else if (currentBeat >= 8 && currentBeat <= 40) {
      // Rumus: (beat - 8) % 4 akan menghasilkan 0, 1, 2, 3 secara berurutan
      bgChoice = (currentBeat - 8) % 4; 
    }
    else if (currentBeat >= 150 && currentBeat <= 151){
      bgChoice = 0; // Background 1: Gelap, Kuning
    }
    else if (currentBeat >= 136 && currentBeat <= 168) {
      // Rumus: (beat - 136) % 4 akan menghasilkan 0, 1, 2, 3 secara berurutan
      bgChoice = (currentBeat - 136) % 4; 
    }
    else {
      // Jika di luar beat 8-40, kita bisa gunakan background default (misal 0)
      bgChoice = 0; 
    }

    // --- TERAPKAN VARIASI BACKGROUND ---
    color bgColor;
    color strokeColor1;
    color strokeColor2;
    
    switch(bgChoice) {
      case 0: // Background 1: Gelap, Kuning
        bgColor = color(50);
        strokeColor1 = color(255, 100, 100); // Merah
        strokeColor2 = color(200, 200, 100); // Kuning
        break;
      case 1: // Background 2: Biru Gelap, Cyan
        bgColor = color(10, 20, 50);
        strokeColor1 = color(100, 255, 255); // Cyan
        strokeColor2 = color(100, 150, 255); // Biru terang
        break;
      case 2: // Background 3: Hijau Gelap, Hijau Neon
        bgColor = color(10, 40, 10);
        strokeColor1 = color(100, 255, 100); // Hijau
        strokeColor2 = color(200, 255, 100); // Hijau kekuningan
        break;
      case 3: // Background 4: Ungu Gelap, Magenta
        bgColor = color(40, 10, 50);
        strokeColor1 = color(255, 100, 255); // Magenta
        strokeColor2 = color(150, 100, 255); // Ungu terang
        break;
      default:
        bgColor = color(50);
        strokeColor1 = color(255);
        strokeColor2 = color(200);
    }

    // Terapkan background
    background(bgColor);
    lights(); 
    
    float rotasi = sin(subBeat * PI) * 0.2; 
    
    for (int i = 0; i < 10; i++) {
      pushMatrix();
      translate(width/2, height/2, -i * 200 + z);
      rotateZ(rotasi); 
      
      noFill();
      
      // Gunakan warna stroke yang sudah ditentukan berdasarkan bgChoice
      // Tetap pertahankan efek ganti warna per 4 sub-beat (1 birama) seperti sebelumnya
      if (subBeat % 4 == 0) {
        stroke(strokeColor1); 
      } else {
        stroke(strokeColor2); 
      }
      
      box(300); 
      popMatrix();
    }
    
    z += 5; 
    if (z > 200) z = 0;
  }
}