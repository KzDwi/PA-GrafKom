// =====================================================================
//  el_RuangTV.pde   [ELEMENT 2D - ADEGAN BINGKAI -> TV]
//  Menggunakan ruangan dari ElRuangBeat (indeks ruangan berganti tiap beat
//  mengikuti array `urut`), lalu gambarnya diambil lewat kanvas offscreen
//  dan di-BLUR.
//
//  Pemakaian:
//    ruangTV = new ElRuangTV(ruangBeat);   // di setup(), setelah ruangBeat dibuat
//    ruangTV.show(clock);                  // di draw(), saat beat >= 329
// =====================================================================
class ElRuangTV {
  // ---- jadwal (satuan beat) ----
  float A_MULAI = 329;       // beat saat bingkai mulai muncul
  float A_AKHIR = 343;       // beat saat zoom-out selesai (gambar = ukuran layar TV)
  float E_AKHIR = 344.5;     // beat saat error hitam-putih selesai, TV menyala
  float OFF_MULAI = 356;     // beat saat TV mulai mati (layar menutup dari tepi ke tengah)
  float OFF_DUR = 0.8;       // durasi animasi menutup (beat); gelap penuh di OFF_MULAI + 1.2*OFF_DUR

  // ---- ukuran layar TV akhir (px, untuk window 1280x720) ----
  float scrW = 587, scrH = 440;   // lebar & tinggi kaca layar TV
  float scrCX, scrCY;              // titik tengah layar TV di layar

  // ---- tampilan ----
  float dimTV = 0.55;        // kecerahan gambar di dalam TV (1 = normal)
  float blurA = 1.0;         // radius blur adegan bingkai (kanvas 1/2 ukuran)
  float blurB = 1.5;         // radius blur di dalam TV (kanvas ~1/5 ukuran)

  ElRuangBeat ruang;         // sumber ruangan yang dipakai sebagai isi layar
  PGraphics bufA, bufB;      // kanvas offscreen: blur sedang (bufA) & blur kuat (bufB)
  PImage vigImg;             // tekstur gradasi gelap di tepi gambar (vignette)
  color avg = color(120, 100, 50);   // warna rata-rata ruangan, dipakai untuk cahaya TV
  int[] urut = { 6, 10, 3, 13, 1, 8, 14, 5, 11, 0, 9, 2, 15, 7, 12, 4 };  // urutan indeks ruangan yang diputar tiap beat

  ElRuangTV(ElRuangBeat r) { ruang = r; }

  // ------------------------------------------------------------------
  void show(BeatClock t) {
    scrCX = width / 2.0;
    scrCY = height / 2.0 - 7;   // geser -7 px agar bodi + panel bawah seimbang
    float b = t.beatPos;
    if (b < A_MULAI) return;
    if (b >= OFF_MULAI + OFF_DUR * 1.2) return;   // sudah hitam penuh: tidak menggambar apa-apa
    siap();
    hint(DISABLE_DEPTH_TEST);
    noLights();
    rectMode(CORNER);
    imageMode(CORNER);
    if (b < A_AKHIR) showBingkai(t);   // fase zoom-out bingkai
    else             showTV(t);        // fase error / TV menyala / TV mati
    hint(ENABLE_DEPTH_TEST);
  }

  // buat kanvas & tekstur vignette sekali saja (lazy init)
  void siap() {
    if (bufA == null) {
      bufA = createGraphics(640, 360, P2D);
      bufB = createGraphics(256, 144, P2D);
      vigImg = createImage(128, 96, ARGB);
      vigImg.loadPixels();
      for (int j = 0; j < 96; j++) for (int i = 0; i < 128; i++) {
        float dx = (i - 63.5) / 64.0, dy = (j - 47.5) / 48.0;
        float d = constrain((sqrt(dx * dx + dy * dy) - 0.55) / 0.6, 0, 1);
        vigImg.pixels[j * 128 + i] = color(0, 0, 0, 200 * d * d);
      }
      vigImg.updatePixels();
    }
  }

  // Render ruangan beat saat ini ke kanvas kecil, lalu blur.
  // `kuat` = true -> pakai bufB (blur lebih kuat); false -> bufA.
  PGraphics ambil(BeatClock t, boolean kuat) {
    int idx = urut[((t.beat - (int) A_MULAI) % urut.length + urut.length) % urut.length];
    ruang.tempel = false;
    ruang.showRuang(t, idx, t.frac, 70);
    ruang.tempel = true;
    PGraphics dst = kuat ? bufB : bufA;
    dst.beginDraw();
    dst.background(0);
    dst.image(ruang.cv.pg, 0, 0, dst.width, dst.height);
    dst.filter(BLUR, kuat ? blurB : blurA);
    dst.endDraw();
    // hitung warna rata-rata dari 9 titik sampel (untuk cahaya TV)
    dst.loadPixels();
    float r = 0, g2 = 0, bl = 0;
    for (int j = 1; j < 4; j++) for (int i = 1; i < 4; i++) {
      color c = dst.pixels[(dst.height * j / 4) * dst.width + dst.width * i / 4];
      r += red(c); g2 += green(c); bl += blue(c);
    }
    avg = lerpColor(avg, color(r / 9, g2 / 9, bl / 9), 0.4);
    return dst;
  }

  // =====================================================================
  //  A. BINGKAI ZOOM OUT (beat A_MULAI .. A_AKHIR)
  // =====================================================================
  void showBingkai(BeatClock t) {
    float p = constrain((t.beatPos - A_MULAI) / (A_AKHIR - A_MULAI), 0, 1);
    float e = p * p * (3 - 2 * p);                       // smoothstep dari 0..1
    float s = lerp(1.0, scrH / 720.0, e);                // skala gambar (menyusut)
    float cx = width / 2.0, cy = lerp(height / 2.0, scrCY, e);  // titik tengah gambar
    float w = 960 * s * (width / 1280.0), h = 720 * s * (height / 720.0);

    noStroke();
    fill(5, 4, 3);
    rect(0, 0, width, height);

    PGraphics im = ambil(t, false);
    float punch = pow(1 - t.frac, 3);                   // punch = kilatan tiap beat (memudar dalam 1 beat)
    edgeGlow(cx, cy, w, h, avg, 1.0 + 0.3 * punch);
    gambar(im, cx, cy, w, h, 1.0, 46 * s, punch);
    scanlinesGlobal();
  }

  // Gambar blur + bloom + RGB split + scanline + vignette, lalu topeng sudut membulat.
  // `dim` = kecerahan, `rad` = radius sudut, `punch` = kilatan per beat.
  void gambar(PImage im, float cx, float cy, float w, float h, float dim, float rad, float punch) {
    float x0 = cx - w / 2, y0 = cy - h / 2;
    noStroke();
    tint(255 * dim);
    image(im, x0, y0, w, h);
    blendMode(ADD);
    tint(255, 255 * dim * 0.18);                       // bloom lembut
    image(im, x0 - w * 0.025, y0 - h * 0.025, w * 1.05, h * 1.05);
    tint(255, 40, 40, 38 * dim);                       // RGB split kanan
    image(im, x0 + 3, y0, w, h);
    tint(40, 255, 255, 30 * dim);                      // RGB split kiri
    image(im, x0 - 3, y0, w, h);
    blendMode(BLEND);
    noTint();
    // scanline halus di dalam gambar
    stroke(0, 34);
    strokeWeight(1);
    for (float y = y0; y < y0 + h; y += 3) line(x0, y, x0 + w, y);
    noStroke();
    image(vigImg, x0, y0, w, h);
    if (punch > 0.02) { fill(255, 235, 200, 14 * punch); rect(x0, y0, w, h); }
    maskBulat(cx, cy, w, h, rad, color(5, 4, 3));
  }

  // Cahaya lembut di luar tepi gambar.
  void edgeGlow(float cx, float cy, float w, float h, color c, float k) {
    blendMode(ADD);
    noFill();
    for (int i = 0; i < 12; i++) {
      float g2 = i * 5;
      stroke(red(c), green(c), blue(c), (22 - i * 1.8) * k * 0.55);
      strokeWeight(6);
      rect(cx - w / 2 - g2, cy - h / 2 - g2, w + g2 * 2, h + g2 * 2, 50 + g2);
    }
    blendMode(BLEND);
    noStroke();
  }

  // Garis scanline tipis di seluruh layar (kesan monitor CRT).
  void scanlinesGlobal() {
    stroke(255, 7);
    strokeWeight(1);
    for (float y = 0; y < height; y += 4) line(0, y, width, y);
    noStroke();
  }

  // Topeng sudut: hanya 4 sudut gambar yang digelapkan, sehingga tepi gambar
  // tampak membulat. `r` = radius, `c` = warna topeng.
  void maskBulat(float cx, float cy, float w, float h, float r, color c) {
    float x0 = cx - w / 2, y0 = cy - h / 2, x1 = cx + w / 2, y1 = cy + h / 2;
    r = min(r, min(w, h) / 2.5);
    noStroke();
    fill(c);
    beginShape();
    vertex(x0 - 1, y0 - 1); vertex(x1 + 1, y0 - 1); vertex(x1 + 1, y1 + 1); vertex(x0 - 1, y1 + 1);
    beginContour();
    int n = 7;                                          // jumlah segmen tiap lengkung sudut
    float[][] cc = { { x0 + r, y0 + r, -90 }, { x0 + r, y1 - r, 180 }, { x1 - r, y1 - r, 90 }, { x1 - r, y0 + r, 0 } };
    for (int k = 0; k < 4; k++) {
      for (int i = 0; i <= n; i++) {
        float a = radians(cc[k][2] - 90.0 * i / n);
        vertex(cc[k][0] + r * cos(a), cc[k][1] + r * sin(a));
      }
    }
    endContour();
    endShape(CLOSE);
  }

  // =====================================================================
  //  B. ERROR HITAM-PUTIH -> TV MENYALA (beat A_AKHIR .. OFF_MULAI)
  // =====================================================================
  void showTV(BeatClock t) {
    float b = t.beatPos;
    if (b >= OFF_MULAI) { showMati(t, (b - OFF_MULAI) / OFF_DUR); return; }
    float u = constrain((b - A_AKHIR) / (E_AKHIR - A_AKHIR), 0, 1);   // 0..1 selama fase error
    float punch = pow(1 - t.frac, 3);

    // Fase: bingkai terakhir -> static penuh layar -> TV + isi layar menyala.
    boolean kuat = u > 0.4;
    float tvA   = sst(0.35, 0.8, u);                                 // TV + cahaya sekitar muncul
    float isiA  = sst(0.55, 1.0, u);                                 // isi layar (ruangan) muncul dari static
    float full  = sst(0.12, 0.28, u) * (1 - sst(0.5, 0.64, u));      // static hitam-putih SELURUH layar
    float scr   = sst(0.0, 0.2, u) * (1 - sst(0.78, 1.0, u));        // static di dalam layar TV

    noStroke();
    fill(5, 4, 3);
    rect(0, 0, width, height);

    PGraphics im = ambil(t, kuat);
    float x0 = scrCX - scrW / 2, y0 = scrCY - scrH / 2;
    float dim = kuat ? lerp(1.0, dimTV, sst(0.4, 0.7, u)) : 1.0;

    if (tvA > 0.01) drawTV(t, tvA, 1.0 + 0.25 * punch);
    else            edgeGlow(scrCX, scrCY, scrW, scrH, avg, 1.0);

    // isi layar
    float a = kuat ? isiA : 1.0;
    if (a > 0.01) {
      pushStyle();
      gambar2(im, scrCX, scrCY, scrW, scrH, dim, a, punch);
      popStyle();
    }

    // static hitam-putih di dalam layar
    if (scr > 0.01) {
      clip(x0, y0, scrW, scrH);
      staticBW(t, x0 - 80, y0 - 20, scrW + 160, scrH + 40, 14 + 10 * (int) (4 * hs(floor(b * 20))), scr);
      noClip();
    }
    // kilatan putih CRT saat TV baru menyala
    if (u > 0.72 && u < 1.0) {
      fill(255, 120 * (1 - (u - 0.72) / 0.28));
      rect(x0, y0, scrW, scrH);
    }

    // static layar penuh (paling parah di fase error)
    if (full > 0.01) {
      staticBW(t, -40, -40, width + 80, height + 80, 20 + 20 * (int) (3 * hs(floor(b * 17) + 3)), full);
      // pita putih sobekan horizontal
      fill(255, 220 * full);
      for (int i = 0; i < 4; i++) rect(0, hs(floor(b * 23) * 7 + i) * height, width, 3 + 18 * hs(i + floor(b * 23)));
    }
    scanlinesGlobal();
  }

  // =====================================================================
  //  C. TV MATI  (q = 0..1.2 ; 1.0 = layar sudah menutup penuh)
  // =====================================================================
  void showMati(BeatClock t, float q) {
    float punch = pow(1 - t.frac, 3);
    float kd = sst(0.25, 1.1, q);                  // cahaya TV & sekitar menggelap
    float p1 = sst(0.0, 0.62, q);                  // layar menipis vertikal jadi garis
    float p2 = sst(0.6, 0.92, q);                  // garis menyusut ke titik
    float cx = scrCX, cy = scrCY;

    noStroke();
    fill(5, 4, 3);
    rect(0, 0, width, height);
    PGraphics im = ambil(t, true);
    drawTV(t, 1 - kd, 1.0 + 0.25 * punch);
    fill(7, 7, 6);                                       // kaca layar gelap (terlihat saat gambar menipis)
    rect(cx - scrW / 2, cy - scrH / 2, scrW, scrH, 40);

    float w = scrW * (1 - 0.92 * p2), h = max(3, scrH * (1 - p1));
    if (w > 24 && h > 3.5) {
      gambar2(im, cx, cy, w, h, dimTV * (1 + 0.9 * p1), 1.0, punch * (1 - p1));
      // redup dari pinggiran ke tengah
      float e = sst(0.0, 0.8, q);
      float bw = w * 0.5 * e, bh = h * 0.5 * e;
      float x0 = cx - w / 2, x1 = cx + w / 2, y0 = cy - h / 2, y1 = cy + h / 2;
      beginShape(QUADS);
      fill(5, 4, 3, 255); vertex(x0, y0); fill(5, 4, 3, 0); vertex(x0 + bw, y0); vertex(x0 + bw, y1); fill(5, 4, 3, 255); vertex(x0, y1);
      fill(5, 4, 3, 0);   vertex(x1 - bw, y0); fill(5, 4, 3, 255); vertex(x1, y0); vertex(x1, y1); fill(5, 4, 3, 0); vertex(x1 - bw, y1);
      fill(5, 4, 3, 255); vertex(x0, y0); vertex(x1, y0); fill(5, 4, 3, 0); vertex(x1, y0 + bh); vertex(x0, y0 + bh);
      fill(5, 4, 3, 0);   vertex(x0, y1 - bh); vertex(x1, y1 - bh); fill(5, 4, 3, 255); vertex(x1, y1); vertex(x0, y1);
      endShape();
      // tengah makin putih (fosfor menyala)
      float wh = sst(0.2, 0.75, q);
      blendMode(ADD);
      for (int i = 0; i < 6; i++) {
        fill(255, 238, 205, 16 * wh);
        ellipse(cx, cy, w * (1 - i * 0.14), h * (1 - i * 0.14) + 4);
      }
      blendMode(BLEND);
    }

    // garis putih tipis + kilau memanjang
    float fadeOut = 1 - sst(0.95, 1.2, q);
    float la = sst(0.4, 0.62, q) * fadeOut;
    if (la > 0.01) {
      blendMode(ADD);
      noStroke();
      fill(255, 255 * la);
      rect(cx - w / 2, cy - 1.5, w, 3);
      streak(cx, cy, 0, 1.5, 230 * la, 0.9 * width);
      streak(cx, cy, 0, 7, 56 * la, 0.7 * width);
      streak(cx, cy, -24 * p2, 1, 120 * la * p2, 1.0 * width);          // garis ganda tipis di atas
      blendMode(BLEND);
    }

    // bintang putih (kilatan terakhir)
    float sa = sst(0.62, 0.84, q) * fadeOut;
    if (sa > 0.01) {
      float s = lerp(0.35, 1.0, sst(0.62, 0.95, q));
      blendMode(ADD);
      for (int gi = 0; gi < 4; gi++) {
        float k = 1 + gi * 0.75;
        float rx = 150 * s * k, ry = 34 * s * k, wk = ry * 0.16;
        fill(255, 255, 255, 255 * sa * (gi == 0 ? 1 : 0.16));
        beginShape();
        vertex(cx, cy - ry); vertex(cx + wk, cy - wk); vertex(cx + rx, cy); vertex(cx + wk, cy + wk);
        vertex(cx, cy + ry); vertex(cx - wk, cy + wk); vertex(cx - rx, cy); vertex(cx - wk, cy - wk);
        endShape(CLOSE);
      }
      stroke(255, 200 * sa);
      strokeWeight(1);
      line(cx - 26 * s, cy - 26 * s, cx + 26 * s, cy + 26 * s);        // kilap diagonal kecil
      line(cx - 26 * s, cy + 26 * s, cx + 26 * s, cy - 26 * s);
      noStroke();
      blendMode(BLEND);
    }
    scanlinesGlobal();
  }

  // Garis kilau horizontal: terang di tengah, memudar ke kedua ujung.
  // `dy` = offset vertikal dari cy, `th` = setengah ketebalan, `panjang` = panjang total.
  void streak(float cx, float cy, float dy, float th, float alpha, float panjang) {
    float xa = cx - panjang / 2, xb = cx + panjang / 2;
    beginShape(QUADS);
    fill(255, 0);     vertex(xa, cy + dy - th);
    fill(255, alpha); vertex(cx, cy + dy - th); vertex(cx, cy + dy + th);
    fill(255, 0);     vertex(xa, cy + dy + th);
    fill(255, alpha); vertex(cx, cy + dy - th);
    fill(255, 0);     vertex(xb, cy + dy - th); vertex(xb, cy + dy + th);
    fill(255, alpha); vertex(cx, cy + dy + th);
    endShape();
  }

  // Isi layar TV: gambar blur yang diredupkan (alpha `a`), sudut layar membulat gelap.
  void gambar2(PImage im, float cx, float cy, float w, float h, float dim, float a, float punch) {
    float x0 = cx - w / 2, y0 = cy - h / 2;
    float flick = 0.94 + 0.06 * noise(frameCount * 0.07);   // kedip halus khas CRT
    noStroke();
    tint(255 * dim * flick, 255 * a);
    image(im, x0, y0, w, h);
    blendMode(ADD);
    tint(255, 255 * dim * 0.14 * a);
    image(im, x0 - w * 0.02, y0 - h * 0.02, w * 1.04, h * 1.04);
    tint(255, 40, 40, 30 * dim * a);
    image(im, x0 + 3, y0, w, h);
    tint(40, 255, 255, 24 * dim * a);
    image(im, x0 - 3, y0, w, h);
    blendMode(BLEND);
    noTint();
    stroke(0, 40 * a);
    strokeWeight(1);
    for (float y = y0; y < y0 + h; y += 3) line(x0, y, x0 + w, y);
    noStroke();
    image(vigImg, x0, y0, w, h);
    // pantulan kaca (garis miring tipis kiri-atas)
    beginShape();
    fill(255, 38 * a); vertex(x0 + w * 0.05, y0 + h * 0.04);
    fill(255, 0);      vertex(x0 + w * 0.55, y0 + h * 0.04);
    fill(255, 0);      vertex(x0 + w * 0.05, y0 + h * 0.5);
    endShape(CLOSE);
    fill(255, 12 * punch * a);
    rect(x0, y0, w, h);
    maskBulat(cx, cy, w, h, 40, color(6, 6, 5));
  }

  // ------------------------------------------------------------------
  //  Bodi TV (plastik, bezel, panel kontrol) + cahaya sekitar
  //  berwarna rata-rata ruangan. `al` = alpha tampil, `glowK` = kekuatan cahaya.
  // ------------------------------------------------------------------
  void drawTV(BeatClock t, float al, float glowK) {
    float x0 = scrCX - scrW / 2, y0 = scrCY - scrH / 2, x1 = scrCX + scrW / 2, y1 = scrCY + scrH / 2;
    float ar = red(avg) / 255.0, ag = green(avg) / 255.0, ab = blue(avg) / 255.0;

    // cahaya yang tumpah dari layar ke ruangan gelap
    blendMode(ADD);
    noStroke();
    for (int i = 0; i < 40; i++) {
      fill(255 * ar, 255 * ag, 255 * ab, map(i, 0, 40, 3.2, 0) * glowK * al);
      ellipse(scrCX, scrCY + 20, 1500 - i * 26, 1000 - i * 17);
    }
    blendMode(BLEND);

    // bodi plastik (gelap, hanya disinari layar)
    fill(46 * al + 5 * (1 - al), 46 * al + 4 * (1 - al), 42 * al + 3 * (1 - al));
    rect(x0 - 74, y0 - 62, scrW + 148, scrH + 150, 28);
    // permukaan bezel: lebih terang dekat layar (disinari)
    blendMode(ADD);
    noFill();
    for (int i = 0; i < 12; i++) {
      float g2 = 5 + i * 5.5;
      stroke(255 * ar, 255 * ag, 255 * ab, (26 - i * 2.0) * glowK * al * 0.8);
      strokeWeight(6);
      rect(x0 - g2, y0 - g2, scrW + g2 * 2, scrH + g2 * 2, 40 + g2 * 0.5);
    }
    blendMode(BLEND);
    // cekungan di sekeliling layar
    noFill();
    stroke(8, 8, 7, 230 * al);
    strokeWeight(16);
    rect(x0 - 8, y0 - 8, scrW + 16, scrH + 16, 44);
    // panel kontrol di bawah layar
    noStroke();
    fill(22 * al + 5 * (1 - al), 22 * al + 4 * (1 - al), 20 * al + 3 * (1 - al));
    rect(x0 - 40, y1 + 22, scrW + 80, 54, 10);
    fill(10, 10, 9, 240 * al);
    rect(scrCX - 52, y1 + 36, 104, 26, 4);                       // kotak display gelap
    fill(190, 50, 40, (90 + 90 * pow(1 - t.frac, 3)) * al);      // lampu kecil berkedip tiap beat
    ellipse(scrCX + 80, y1 + 49, 6, 6);
    fill(58, 58, 54, 200 * al);
    for (int i = 0; i < 6; i++) rect(x0 - 10 + i * 24, y1 + 41, 16, 7, 2);
    for (int i = 0; i < 6; i++) rect(x1 - 130 + i * 24, y1 + 41, 16, 7, 2);
    // garis grill speaker samping
    stroke(0, 70 * al);
    strokeWeight(2);
    for (float yy = y0 + 20; yy < y1 - 10; yy += 8) { line(x0 - 60, yy, x0 - 24, yy); line(x1 + 24, yy, x1 + 60, yy); }
    noStroke();
  }

  // ------------------------------------------------------------------
  //  Static hitam-putih kotak-kotak (dalam 1 beginShape).
  //  `bs` = ukuran blok, `dens` = kerapatan (0..1) blok yang tampil.
  //  Sebagian baris tergeser acak untuk kesan tracking error.
  // ------------------------------------------------------------------
  void staticBW(BeatClock t, float x, float y, float w, float h, int bs, float dens) {
    int st = floor(t.beatPos * 26);                       // seed berganti cepat seiring beat
    noStroke();
    beginShape(QUADS);
    int row = 0;
    for (float yy = y; yy < y + h; yy += bs) {
      float off = (hs(st * 31 + row * 7) < 0.16) ? (hs(st + row * 3) * 2 - 1) * bs * 3 : 0;
      int col = 0;
      for (float xx = x; xx < x + w; xx += bs) {
        float r1 = hs(st * 977 + row * 131 + col * 17);
        if (r1 < dens) {
          float v = hs(st * 53 + row * 19 + col * 29) > 0.5 ? 255 : 0;
          fill(v);
          vertex(xx + off, yy); vertex(xx + off + bs, yy); vertex(xx + off + bs, yy + bs); vertex(xx + off, yy + bs);
        }
        col++;
      }
      row++;
    }
    endShape();
  }

  // ---------- utilitas ----------
  // hash 1D deterministik -> nilai 0..1 (pengganti random() agar stabil per beat)
  float hs(float n) {
    float v = sin(n * 12.9898 + 78.233) * 43758.5453;
    return v - floor(v);
  }
  // smoothstep: 0 sebelum a, 1 setelah b, halus di antaranya
  float sst(float a, float b, float x) {
    float k = constrain((x - a) / (b - a), 0, 1);
    return k * k * (3 - 2 * k);
  }
}