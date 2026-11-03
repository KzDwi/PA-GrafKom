// =====================================================================
//  el_tvstatic.pde   [ELEMENT 2D]
//  Menampilkan TV retro dengan pilihan latar ruangan animasi.
// =====================================================================
class ElTvStatic {
  
  int lastRoom = -1;
  float roomStartBeat = 0;

  ElTvStatic() { }

  void show(BeatClock t, int room) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    
    if (room != lastRoom) {
      roomStartBeat = t.beatPos;
      lastRoom = room;
    }
    
    if (room == 1) {
      drawRoom1(t); 
    } else if (room == 2) {
      drawRoom2(t); 
    } else if (room == 3) {
      drawRoom3(t); // Tape Terang
    } else if (room == 4) {
      drawRoom4(t); // Tape Gelap Zoom-In + Karakter
    }
    
    hint(ENABLE_DEPTH_TEST); 
  }

  // ==========================================
  // RUANGAN 1: TV Besar di Tengah
  // ==========================================
  void drawRoom1(BeatClock t) {
    float localBeat = max(0, t.beatPos - roomStartBeat); 
    pushMatrix();
    translate(width / 2, height / 2);
    float cinematicZoom = 1.0 + (localBeat * 0.002); 
    scale(cinematicZoom);
    translate(-width / 2, -height / 2);

    fill(8, 7, 5); rectMode(CORNER); rect(0, 0, width, height);
    noStroke();
    for (int i = 0; i < 40; i++) { fill(8, 7, 5, 255 - (i * 6)); rect(width - 450 + (i * 5), 0, 10, height); }

    float lightX = width / 2 - 120, lightY = height / 2 + 120;
    for (int i = 0; i < 50; i++) { fill(255, 230, 140, 2); ellipse(lightX, lightY, 600 - i * 11, 150 - i * 2.8); }
    for (int i = 0; i < 20; i++) { fill(255, 240, 180, 3); ellipse(lightX, lightY, 200 - i * 9, 50 - i * 2.2); }

    for (int i = 0; i < 35; i++) {
      float px = noise(i * 10) * width; 
      float py = height + 50 - ((t.beatPos * 35 + noise(i) * 800) % (height + 100)); 
      float drift = (noise(i, t.beatPos * 0.05) * 20) - 10; 
      fill(255, 220, 150, noise(i * 20) * 150); ellipse(px + drift, py, 3, 3);
    }

    pushMatrix(); translate(width / 2 - 160, height / 2 + 50); scale(0.35); drawTVCore(t); popMatrix();
    pushMatrix(); translate(width / 2 - 40, height / 2 + 130); noStroke();
    fill(0, 150);       quad(-45, 2, 35, -13, 45, 2, -35, 17);
    fill(25, 25, 25);   quad(-40, 0, 40, -15, 50, 0, -30, 15);
    fill(15, 15, 15);   quad(-40, 0, -30, 15, -30, 10, -40, -5); quad(-30, 15, 50, 0, 50, -5, -30, 10);
    fill(200, 30, 30);  quad(-20, -2, 20, -10, 25, -2, -15, 6);
    popMatrix(); popMatrix(); 
  }

  // ==========================================
  // RUANGAN 2: TV Kecil Ruang Gelap
  // ==========================================
  void drawRoom2(BeatClock t) {
    float localBeat = max(0, t.beatPos - roomStartBeat); 
    pushMatrix(); translate(width / 2, height / 2);
    float cinematicZoom = 1.0 + (localBeat * 0.0095); scale(cinematicZoom); translate(-width / 2, -height / 2);

    fill(8, 7, 5); rectMode(CORNER); rect(0, 0, width, height);

    noStroke();
    for (int i = 0; i < 60; i++) { fill(255, 220, 130, map(i, 0, 60, 2.5, 0)); ellipse(width / 2, height / 2 - 30, 1200 - i * 20, 900 - i * 15); }
    float tvFlicker = noise(t.beatPos * 0.5) * 4; 
    for (int i = 0; i < 45; i++) { fill(170, 215, 255, map(i, 0, 45, 4 + tvFlicker, 0)); ellipse(width / 2, height / 2 + 250, 850 - i * 18, 220 - i * 5); }

    fill(0, 240); ellipse(width / 2, height / 2 + 220, 480, 70); fill(0, 140); ellipse(width / 2, height / 2 + 220, 650, 110); 
    pushMatrix(); translate(width / 2, height / 2 + 40); scale(1.2); drawTVCore(t); popMatrix();
    popMatrix(); 
  }

  // ==========================================
  // RUANGAN 3: Latar Tape Terang
  // ==========================================
  void drawRoom3(BeatClock t) {
    drawScrollingTape(t); 
  }
  
  // ==========================================
  // RUANGAN 4: Tape Gelap + Efek ZOOM-IN Dikit
  // ==========================================
  void drawRoom4(BeatClock t) {
    pushMatrix();
    
    // Zoom In 15% khusus untuk Room 4
    translate(width / 2, height / 2);

    translate(-width / 2, -height / 2);

    drawScrollingTape(t); // Latar ditarik normal, ikut membesar karena di-scale
    
    // Overlay Hitam Transparan
    fill(10, 8, 5, 110); 
    rectMode(CORNER);
    noStroke();
    // Diperlebar agar layar tetap tertutup gelap meski sudah di-zoom
    rect(-width, -height, width * 3, height * 3);
    
    // Orang masuk
    drawWalkingCharacter(t);
    
    popMatrix();
  }

  // ==========================================
  // LOGIKA INTI PERGESERAN PITA KASET (TAPE)
  // ==========================================
  void drawScrollingTape(BeatClock t) {
    float viewH = 340; 
    fill(0); noStroke(); rectMode(CORNER); rect(0, 0, width, height);
    float viewY = (height - viewH) / 2;
    pushMatrix(); translate(0, viewY);

    float speed = 30;           
    float pixelStep = 6;         
    float segmentWidth = 600; 

    float rawScroll = (t.beatPos * speed) % segmentWidth;
    float scrollX   = floor(rawScroll / pixelStep) * pixelStep;

    for (float x = -scrollX - segmentWidth; x < width + segmentWidth; x += segmentWidth) {
      pushMatrix(); translate(x, 0); rectMode(CORNER); noStroke();
      
      fill(38, 35, 20); rect(0, 0, segmentWidth, viewH);
      fill(30, 28, 15);
      for (int i = 0; i < segmentWidth; i += 60) {
        rect(i, 0, 20, viewH); rect(i - 10, viewH/2 - 30, 40, 60); 
      }
      fill(190, 160, 80); rect(0, 0, segmentWidth, 18);
      fill(15, 14, 10); rect(segmentWidth - 60, 0, 60, viewH);
      fill(100, 85, 40); rect(segmentWidth - 60, 0, 60, 18); 
      popMatrix();
    }

    noStroke();
    for(int i = 0; i < 25; i++) { fill(255, 240, 180, 2.5); ellipse(0, viewH - 40, 500 - i*15, 500 - i*15); }

    noStroke();
    for (int i = 0; i < 300; i++) {
      float alpha = pow(map(i, 0, 300, 0, 1), 2.5) * 255; 
      fill(0, alpha); rect(width - 300 + i, 0, 2, viewH);
    }
    
    for (int i = 0; i < 40; i++) {
      fill(0, map(i, 0, 40, 80, 0)); 
      rect(0, i, width, 2); rect(0, viewH - i, width, 2);     
    }

    stroke(0, 200, 200, 150); strokeWeight(2); line(0, 0, width, 0); 
    stroke(200, 0, 0, 150);   line(0, viewH, width, viewH);          
    
    fill(0); noStroke();
    rect(0, -viewY - 10, width, viewY + 10); rect(0, viewH, width, viewY + 10);       
    popMatrix();
  }

  // ==========================================
  // KARAKTER BERJALAN DARI LUAR LAYAR (LURUS TANPA NAIK-TURUN)
  // ==========================================
  void drawWalkingCharacter(BeatClock t) {
    pushMatrix();
    
    float activeBeat = max(0, t.beatPos - 72);
    
    // MAJU LEBIH LAMBAT
    float charX = -30 + (activeBeat * 15); 
    charX = min(charX, width / 2 - 100); 
    
    float viewH = 340; 
    float viewY = (height - viewH) / 2;
    float charY = viewY + viewH - 60; // Tinggi pijakan lantai
    
    translate(charX, charY);
    scale(5); // Skala diperbesar
    noStroke();
    
    // SIKLUS ANIMASI KAKI (Efek bobbing/naik-turun badan sudah dihilangkan)
    float walkCycle = t.beatPos * PI; 
    
    // Warna palet sesuai gambar referensi
    color colHair  = color(35, 30, 20);   
    color colSkin  = color(180, 150, 80); 
    color colEye   = color(100, 110, 80); 
    color colShirt = color(60, 60, 50);   
    color colShoe  = color(25, 20, 15);   

    // --- MENGGAMBAR PIKSEL KARAKTER ---
    
    // 1. Rambut Belakang & Dasar Kepala
    fill(colHair);
    rect(-9, -20, 18, 14); 
    rect(-10, -18, 2, 10); 
    rect(8, -17, 3, 10);   
    rect(-4, -22, 3, 2);   

    // 2. Wajah (Kulit)
    fill(colSkin);
    rect(-5, -12, 12, 7);  

    // 3. Detail Poni Rambut
    fill(colHair);
    rect(-7, -12, 6, 3);   
    rect(-1, -12, 3, 5);   
    rect(3, -12, 5, 2);    
    rect(-5, -9, 3, 2);    

    // 4. Mata
    fill(colEye);
    rect(-2, -10, 2, 2);   
    rect(4, -10, 2, 2);    

    // 5. Baju Utama
    fill(colShirt);
    rect(-6, -5, 12, 8);   

    // 6. Tangan (Mengapit badan)
    fill(colSkin);
    rect(-9, -5, 4, 7);    
    rect(5, -5, 4, 7);     

    // 7. Kaki & Sepatu (Dianimasikan Berjalan)
    float legLift = abs(sin(walkCycle)) * -2; // Kaki tetap diangkat sedikit agar terlihat melangkah
    
    // Logika langkah kaki (gantian kiri dan kanan)
    if (t.beat % 2 == 0) {
      // Langkah Kiri
      fill(colSkin); rect(-5, 3, 4, 3); // Paha kiri diam
      fill(colShoe); rect(-6, 6, 6, 2); // Sepatu kiri diam
      
      fill(colSkin); rect(2, 3 + legLift, 4, 3); // Paha kanan terangkat
      fill(colShoe); rect(1, 6 + legLift, 6, 2); // Sepatu kanan terangkat
    } else {
      // Langkah Kanan
      fill(colSkin); rect(-5, 3 + legLift, 4, 3); // Paha kiri terangkat
      fill(colShoe); rect(-6, 6 + legLift, 6, 2); // Sepatu kiri terangkat
      
      fill(colSkin); rect(2, 3, 4, 3); // Paha kanan diam
      fill(colShoe); rect(1, 6, 6, 2); // Sepatu kanan diam
    }

    popMatrix();
  }

  // ==========================================
  // FUNGSI INTI PEMBUAT TV
  // ==========================================
  void drawTVCore(BeatClock t) {
    rectMode(CENTER);
    fill(190, 195, 175); stroke(30); strokeWeight(6); rect(0, 0, 480, 360, 40);
    fill(140, 145, 125); noStroke(); rect(0, 140, 200, 15, 10); 
    fill(20, 25, 20); stroke(40); strokeWeight(12); rect(0, -20, 400, 260, 50);
    noStroke();
    for (int i = 0; i < 1500; i++) {
      float rx = random(-180, 180), ry = random(-130, 90);
      fill(random(30, 220)); rect(rx, ry, random(2, 6), random(2, 4));
    }
    stroke(0, 80); strokeWeight(2);
    for (float y = -140; y < 100; y += 6) line(-190, y, 190, y);
    if (random(1) < 0.15 || t.newBeat) {
       fill(255, 60); noStroke(); rect(0, random(-100, 80), 380, random(5, 25));
    }
  }  
}
