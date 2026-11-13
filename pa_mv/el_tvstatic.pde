// =====================================================================
//  el_tvstatic.pde   [ELEMENT 2D]
//  Menampilkan TV retro dengan pilihan latar ruangan animasi
//  (ruangan 1-3 statis/zoom, ruangan 4 = terowongan + anak berjalan).
// =====================================================================
class ElTvStatic {

  int lastRoom = -1;          // indeks ruangan yang terakhir aktif
  float roomStartBeat = 0;    // beatPos saat ruangan mulai aktif (untuk animasi lokal)

  // ===== JADWAL ANAK LAKI-LAKI (satuan SUBBEAT; 1 beat = 2 subbeat) =====
  // index 0 = mulai masuk ruangan, 1..3 = teleport ke-1..3
  int[]   boySub    = { 145,  158,  174,  191 };
  // posisi X anak saat masuk / tiap teleport (px)
  float[] boyStartX = { -30,  380,  700,  980 };
  // kecepatan jalan anak di antara teleport (px per beat)
  float boySpeed = 20;
  // beat saat adegan ruangan ini berakhir (anak harus tiba di ujung kanan)
  float boyEndBeat = 100;
  // jarak titik tengah anak ke tepi kanan layar saat tiba (anak ~110 px lebar)
  float boyEdgeMargin = 56;

  ElTvStatic() { }

  void show(BeatClock t, int room) {
    hint(DISABLE_DEPTH_TEST);
    noLights();

    // catat beat mulai tiap kali ruangan berganti
    if (room != lastRoom) {
      roomStartBeat = t.beatPos;
      lastRoom = room;
    }

    if (room == 1)      drawRoom1(t);
    else if (room == 2) drawRoom2(t);
    else if (room == 3) drawRoom3(t);   // tape terang
    else if (room == 4) drawRoom4(t);   // tape gelap + karakter

    hint(ENABLE_DEPTH_TEST);
  }

  // ==========================================
  // RUANGAN 1: TV Besar di Tengah
  // ==========================================
  void drawRoom1(BeatClock t) {
    float localBeat = max(0, t.beatPos - roomStartBeat);
    pushMatrix();
    translate(width / 2, height / 2);
    float cinematicZoom = 1.0 + (localBeat * 0.002);     // zoom-in sangat pelan
    scale(cinematicZoom);
    translate(-width / 2, -height / 2);

    fill(8, 7, 5); rectMode(CORNER); rect(0, 0, width, height);
    noStroke();
    for (int i = 0; i < 40; i++) { fill(8, 7, 5, 255 - (i * 6)); rect(width - 450 + (i * 5), 0, 10, height); }

    float lightX = width / 2 - 120, lightY = height / 2 + 120;
    for (int i = 0; i < 50; i++) { fill(255, 230, 140, 2); ellipse(lightX, lightY, 600 - i * 11, 150 - i * 2.8); }
    for (int i = 0; i < 20; i++) { fill(255, 240, 180, 3); ellipse(lightX, lightY, 200 - i * 9, 50 - i * 2.2); }

    // partikel debu melayang naik
    for (int i = 0; i < 35; i++) {
      float px = noise(i * 10) * width;
      float py = height + 50 - ((t.beatPos * 35 + noise(i) * 800) % (height + 100));
      float drift = (noise(i, t.beatPos * 0.05) * 20) - 10;
      fill(255, 220, 150, noise(i * 20) * 150); ellipse(px + drift, py, 3, 3);
    }

    // TV utama + kaset di depannya
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
    float cinematicZoom = 1.0 + (localBeat * 0.0095);    // zoom-in lebih cepat dari ruangan 1
    scale(cinematicZoom); translate(-width / 2, -height / 2);

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
  // RUANGAN 4: Terowongan gelap + anak laki-laki
  // Latar terowongan BERGANTI tiap anak teleport (ukuran terowongan tetap):
  //   style 0 = pita kaset          (sebelum teleport pertama)
  //   style 1 = lorong lengkung hijau (setelah teleport 1)
  //   style 2 = ruang bermain biru    (setelah teleport 2)
  //   style 3 = lorong berpintu kuning(setelah teleport 3) -> sama dgn adegan pintu beat 100
  // Pergantian mengikuti boySub[] sehingga otomatis sinkron dengan teleport + glitch.
  // ==========================================
  void drawRoom4(BeatClock t) {
    pushMatrix();
    drawTunnelBand(t, tunnelStyle(t));   // latar berganti tiap teleport

    // overlay hitam transparan (semua ruangan tetap terasa gelap)
    fill(10, 8, 5, 110);
    rectMode(CORNER);
    noStroke();
    rect(-width, -height, width * 3, height * 3);

    drawWalkingCharacter(t);
    popMatrix();
  }

  // Nomor segmen anak (0 = masuk, 1..3 = setelah teleport 1..3), dihitung dari beatPos
  int boySeg(BeatClock t) {
    float subPos = t.beatPos * 2;
    int seg = 0;
    for (int i = 0; i < boySub.length; i++) {
      if (subPos >= boySub[i]) seg = i;
    }
    return seg;
  }

  // Style latar terowongan = nomor segmen anak (0..3)
  int tunnelStyle(BeatClock t) {
    return constrain(boySeg(t), 0, 3);
  }

  // ==========================================
  // PITA TEROWONGAN (Ruangan 3 = style 0; Ruangan 4 = style 0..3)
  // Ukuran band SAMA untuk semua style (viewH px, letterbox hitam atas-bawah).
  // ==========================================
  void drawScrollingTape(BeatClock t) {
    drawTunnelBand(t, 0);
  }

  void drawTunnelBand(BeatClock t, int style) {
    float viewH = 340;                                   // tinggi pita terowongan
    fill(0); noStroke(); rectMode(CORNER); rect(0, 0, width, height);
    float viewY = (height - viewH) / 2;                  // posisi Y pita (tengah layar)
    pushMatrix(); translate(0, viewY);

    rectMode(CORNER); ellipseMode(CENTER); noStroke();
    if      (style == 1) bandArch(t, viewH);
    else if (style == 2) bandPlay(t, viewH);
    else if (style == 3) bandHall(t, viewH);
    else                 bandTape(t, viewH);

    // ---- efek bersama semua style: kabut kanan, bayangan atas-bawah, garis tepi ----
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

    // tutup hitam di atas & bawah pita (letterbox)
    fill(0); noStroke();
    rect(0, -viewY - 10, width, viewY + 10); rect(0, viewH, width, viewY + 10);
    popMatrix();
  }

  // ---- helper ----
  float fmod(float a, float b) { return a - b * floor(a / b); }
  float hash1(float n) { float s = sin(n * 12.9898) * 43758.5453; return s - floor(s); }

  // Posisi scroll dunia (px). Style 3 (lorong berpintu) melambat lalu BERHENTI
  // di boyEndBeat agar pintu pas di depan anak saat adegan pintu (beat 100) mulai.
  float bandScroll(float beat, int style) {
    float speed = 30, pixelStep = 6;
    float raw = beat * speed;
    if (style == 3) {
      float stopLen   = 2.0;                       // lama fase melambat (beat)
      float stopStart = boyEndBeat - stopLen;
      if (beat > stopStart) {
        float u = constrain((beat - stopStart) / stopLen, 0, 1);
        raw = stopStart * speed + speed * stopLen * (u - u * u * 0.5);
      }
    }
    return floor(raw / pixelStep) * pixelStep;     // snap ke grid agar pixel-art konsisten
  }

  // Warna blok ruang bermain (siklus 4 warna)
  color playCol(int i) {
    switch (((i % 4) + 4) % 4) {
      case 0:  return color(170, 55, 48);
      case 1:  return color(205, 165, 58);
      case 2:  return color(55, 140, 82);
      default: return color(66, 112, 190);
    }
  }

  // ==========================================
  // STYLE 0: PITA KASET
  // ==========================================
  void bandTape(BeatClock t, float viewH) {
    float speed = 30;
    float pixelStep = 6;
    float segmentWidth = 600;                            // lebar satu segmen pita

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
    for (int i = 0; i < 25; i++) { fill(255, 240, 180, 2.5); ellipse(0, viewH - 40, 500 - i*15, 500 - i*15); }
  }

  // ==========================================
  // STYLE 1: LORONG LENGKUNG HIJAU (gelap, lampu gantung kecil)
  // ==========================================
  void bandArch(BeatClock t, float viewH) {
    float P = 420;                                       // jarak antar lengkungan (px)
    float sc = bandScroll(t.beatPos, 1);
    float ox = -fmod(sc, P);

    fill(30, 60, 48); rect(0, 0, width, viewH);          // dinding
    fill(16, 30, 25); rect(0, 0, width, 36);             // plafon

    // lantai kotak-kotak (ikut scroll)
    for (float x = -fmod(sc, 80); x < width; x += 40) {
      int k = round((x + sc) / 40.0);
      if (k % 2 == 0) fill(40, 72, 58); else fill(24, 46, 38);
      rect(x, 300, 40, viewH - 300);
    }

    for (float x = ox - P; x < width + P; x += P) {
      // lengkungan (rongga gelap berlapis)
      fill(10, 22, 18);
      rect(x - 150, 96, 300, 204);
      arc(x, 96, 300, 200, PI, TWO_PI);
      fill(20, 44, 36);
      rect(x - 110, 150, 220, 150);
      arc(x, 150, 220, 140, PI, TWO_PI);
      // lampu gantung kecil di dalam lengkungan
      for (int i = 0; i < 8; i++) { fill(255, 235, 170, 3); ellipse(x, 70, 200 - i * 22, 200 - i * 22); }
      fill(255, 238, 180); ellipse(x, 70, 14, 14);
      fill(40, 36, 24); rect(x - 1, 36, 2, 27);

      // pilar di antara lengkungan
      float lx = x + P / 2;
      fill(44, 84, 68); rect(lx - 60, 0, 120, 300);
      fill(58, 104, 86); rect(lx - 60, 0, 10, 300);
      fill(20, 38, 30); rect(lx - 66, 284, 132, 16);
    }
  }

  // ==========================================
  // STYLE 2: RUANG BERMAIN BIRU (balok busa, bola, lampu bulat)
  // ==========================================
  void bandPlay(BeatClock t, float viewH) {
    float P = 480;                                       // lebar tiap segmen ruang bermain
    float sc = bandScroll(t.beatPos, 2);
    float ox = -fmod(sc, P);

    fill(34, 56, 110); rect(0, 0, width, viewH);         // dinding biru
    fill(46, 78, 140); rect(0, 150, width, 14);          // garis tengah dinding
    fill(20, 34, 72);  rect(0, 0, width, 36);            // plafon

    // lantai matras warna-warni (ikut scroll)
    for (float x = -fmod(sc, 160); x < width; x += 40) {
      int k = round((x + sc) / 40.0);
      fill(playCol(k)); rect(x, 304, 40, viewH - 304);
      fill(0, 70);      rect(x, 304, 40, viewH - 304);
    }

    for (float x = ox - P; x < width + P; x += P) {
      int idx = round((x + sc) / P);

      // 3 balok busa bertumpuk acak di pangkal dinding
      for (int j = 0; j < 3; j++) {
        float bx = x - 160 + j * 100 + (hash1(idx * 7 + j) - 0.5) * 30;
        float bh = 50 + hash1(idx * 3 + j * 5) * 70;
        int ci = (int) (hash1(idx * 13 + j * 3) * 4);
        fill(playCol(ci));       rect(bx, 304 - bh, 70, bh);
        fill(255, 40);           rect(bx, 304 - bh, 70, 8);
        fill(0, 60);             rect(bx + 62, 304 - bh, 8, bh);
      }

      // tumpukan bola
      for (int j = 0; j < 10; j++) {
        float bx = x + 120 + hash1(idx * 11 + j) * 190;
        float by = 294 + hash1(idx * 17 + j) * 12;
        fill(playCol((int) (hash1(idx * 19 + j) * 4)));
        ellipse(bx, by, 26, 26);
        fill(255, 60); ellipse(bx - 5, by - 5, 7, 7);
      }

      // lampu bulat plafon
      float lx = x + P / 2;
      for (int i = 0; i < 8; i++) { fill(200, 225, 255, 3); ellipse(lx, 40, 260 - i * 28, 120 - i * 12); }
      fill(225, 238, 255); ellipse(lx, 28, 56, 14);
    }
  }

  // ==========================================
  // STYLE 3: LORONG BERPINTU KUNING
  // Disamakan dengan latar adegan pintu (el_DoorLoop.pde):
  // dinding mustard, plafon krem + lampu panel putih, pintu cokelat, gagang emas.
  // Dunia melambat & berhenti di boyEndBeat; pintu terakhir berhenti tepat di depan anak.
  // ==========================================
  void bandHall(BeatClock t, float viewH) {
    float P = 640;                                       // jarak antar pintu (px)
    float sc   = bandScroll(t.beatPos, 3);
    float sEnd = bandScroll(boyEndBeat, 3);
    float phase = sEnd + (width - 260);                  // offset agar pintu berhenti di (width-260)
    float ox = -fmod(sc - phase, P);

    fill(120, 100, 40);  rect(0, 40, width, 262);        // dinding
    fill(130, 120, 78);  rect(0, 0, width, 42);          // plafon
    fill(84, 68, 28);    rect(0, 302, width, viewH - 302); // lantai (karpet)
    fill(46, 34, 10);    rect(0, 288, width, 14);        // plinth gelap

    // garis wallpaper vertikal (ikut scroll)
    fill(100, 80, 26);
    for (float x = -fmod(sc, 40); x < width; x += 40) rect(x, 42, 8, 246);

    for (float x = ox - P; x < width + P; x += P) {
      // lampu panel putih di plafon (di antara dua pintu)
      float lx = x + P / 2;
      for (int i = 0; i < 8; i++) { fill(255, 240, 170, 3); ellipse(lx, 46, 440 - i * 40, 110 - i * 10); }
      fill(240, 236, 200); rect(lx - 75, 30, 150, 12);

      // pintu (tertutup)
      float dw = 100, dtop = 76, dbot = 288;
      fill(54, 38, 14);  rect(x - dw / 2 - 8, dtop - 8, dw + 16, dbot - dtop + 8);   // kusen
      fill(90, 58, 22);  rect(x - dw / 2, dtop, dw, dbot - dtop);                    // daun
      fill(66, 42, 15);                                                              // panel
      rect(x - dw / 2 + 12, dtop + 14, dw - 24, 78);
      rect(x - dw / 2 + 12, dtop + 108, dw - 24, 84);
      fill(218, 192, 104); rect(x + dw / 2 - 22, dtop + 100, 7, 7);                   // gagang
    }
  }

  // ==========================================
  // KARAKTER BERJALAN DARI LUAR LAYAR (lurus tanpa naik-turun)
  // Posisi X anak: jalan lurus per beat, lalu "teleport" ke boyStartX di tiap titik
  // jadwal. Dihitung dari beatPos (aman saat pause/restart). Return -9999 kalau
  // belum muncul.
  // ==========================================
  float boyX(BeatClock t) {
    float subPos = t.beatPos * 2;
    if (subPos < boySub[0]) return -9999;
    int seg = 0;
    for (int i = 0; i < boySub.length; i++) {
      if (subPos >= boySub[i]) seg = i;
    }
    float beatsInSeg = (subPos - boySub[seg]) / 2.0;
    float startX = boyStartX[seg];
    // Teleport terakhir: posisi awal dihitung MUNDUR dari ujung kanan layar,
    // supaya anak tepat tiba di tepi kanan pada boyEndBeat.
    if (seg == boySub.length - 1) {
      float beatsToEnd = boyEndBeat - boySub[seg] / 2.0;
      startX = (width - boyEdgeMargin) - beatsToEnd * boySpeed;
    }
    return min(startX + beatsInSeg * boySpeed, width - boyEdgeMargin);
  }

  void drawWalkingCharacter(BeatClock t) {
    if (boyX(t) < -9000) return;   // belum waktunya muncul
    pushMatrix();

    float charX = boyX(t);

    float viewH = 340;
    float viewY = (height - viewH) / 2;
    float charY = viewY + viewH - 60;   // tinggi pijakan lantai

    translate(charX, charY);
    scale(5);                            // skala pixel-art diperbesar
    noStroke();

    float walkCycle = t.beatPos * TWO_PI;  // fase animasi kaki

    // Palet warna karakter
    color colHair  = color(35, 30, 20);
    color colSkin  = color(180, 150, 80);
    color colEye   = color(100, 110, 80);
    color colShirt = color(60, 60, 50);
    color colShoe  = color(25, 20, 15);

    // --- gambar piksel karakter ---

    // 1. rambut belakang & dasar kepala
    fill(colHair);
    rect(-9, -20, 18, 14);
    rect(-10, -18, 2, 10);
    rect(8, -17, 3, 10);
    rect(-4, -22, 3, 2);

    // 2. wajah
    fill(colSkin);
    rect(-5, -12, 12, 7);

    // 3. poni rambut
    fill(colHair);
    rect(-7, -12, 6, 3);
    rect(-1, -12, 3, 5);
    rect(3, -12, 5, 2);
    rect(-5, -9, 3, 2);

    // 4. mata
    fill(colEye);
    rect(-2, -10, 2, 2);
    rect(4, -10, 2, 2);

    // 5. baju
    fill(colShirt);
    rect(-6, -5, 12, 8);

    // 6. tangan mengapit badan
    fill(colSkin);
    rect(-9, -5, 4, 7);
    rect(5, -5, 4, 7);

    // 7. kaki & sepatu (bergantian kiri/kanan tiap subbeat)
    float legLift = abs(sin(walkCycle)) * -2;   // kaki terangkat sedikit saat melangkah

    if (t.subBeat % 2 == 0) {
      // langkah kiri
      fill(colSkin); rect(-5, 3, 4, 3);
      fill(colShoe); rect(-6, 6, 6, 2);
      // langkah kanan (terangkat)
      fill(colSkin); rect(2, 3 + legLift, 4, 3);
      fill(colShoe); rect(1, 6 + legLift, 6, 2);
    } else {
      // langkah kiri (terangkat)
      fill(colSkin); rect(-5, 3 + legLift, 4, 3);
      fill(colShoe); rect(-6, 6 + legLift, 6, 2);
      // langkah kanan
      fill(colSkin); rect(2, 3, 4, 3);
      fill(colShoe); rect(1, 6, 6, 2);
    }

    popMatrix();
  }

  // ==========================================
  // FUNGSI INTI: gambar TV (bodi + layar static)
  // ==========================================
  void drawTVCore(BeatClock t) {
    rectMode(CENTER);
    fill(190, 195, 175); stroke(30); strokeWeight(6); rect(0, 0, 480, 360, 40);
    fill(140, 145, 125); noStroke(); rect(0, 140, 200, 15, 10);
    fill(20, 25, 20); stroke(40); strokeWeight(12); rect(0, -20, 400, 260, 50);
    noStroke();
    // isi layar: titik-titik static acak (digambar ulang tiap frame)
    for (int i = 0; i < 1500; i++) {
      float rx = random(-180, 180), ry = random(-130, 90);
      fill(random(30, 220)); rect(rx, ry, random(2, 6), random(2, 4));
    }
    stroke(0, 80); strokeWeight(2);
    for (float y = -140; y < 100; y += 6) line(-190, y, 190, y);
    // pita putih sesekali (glitch ringan)
    if (random(1) < 0.15 || t.newBeat) {
      fill(255, 60); noStroke(); rect(0, random(-100, 80), 380, random(5, 25));
    }
  }
}