// =====================================================================
// el_MainMenu.pde
// MAIN MENU - REALISTIC BACKROOMS + SUBTLE MOUSE PARALLAX + TERMINAL UI
//
// v3 - fix pass:
//   - lightF: half-wave smootherstep, range 0.72..1.10 (kontras lampu pulih)
//   - detailLampu: lampu digambar sedikit di bawah plafon (CEIL+2) supaya
//                  selalu terlihat, dengan frame tipis di sekelilingnya
//   - detailWallpaper: garis vertikal dijadikan world-fixed (tidak lagi
//                      camera-relative) supaya tidak "nabrak" dengan seam
//   - stripWall: noStroke() di awal, gradient vertikal tetap (pseudo-AO)
//   - fogCol & zBase kontinu tetap dipertahankan dari v2
//
// Integrasi di pa_mv.pde tetap sama:
//   ElMainMenu menu;
//   menu = new ElMainMenu(fontJepang, VOLUME);
//   menu.show();                 // panggil di draw()
//   menu.selesai                 // true setelah fade-out PLAY selesai
//
// Input tetap diteruskan dari sketch utama:
//   void mousePressed()  { if (menu != null) menu.mousePressed(); }
//   void mouseDragged()  { if (menu != null) menu.mouseDragged(); }
//   void mouseReleased() { if (menu != null) menu.mouseReleased(); }
// =====================================================================

class ElMainMenu {
  // ------------------------- DUNIA 3D -------------------------------
  final float FLOOR = 150;
  final float CEIL = -110;
  final float HALLW = 900;
  final float STEP = 50;
  final float FOG_END = 4200;
  final float FAR = 4300;

  Canvas3D cv = new Canvas3D();
  PFont font;
  PImage vig;

  float volume;
  boolean selesai = false;
  boolean memudar = false;
  boolean dragging = false;

  int tMulai;
  int tPlay;

  // Posisi mouse yang sudah dihaluskan (-1 sampai 1).
  float mx = 0;
  float my = 0;

  float hPlay = 0;
  float hVol = 0;

  // UI terminal.
  float uiX = 42;
  float uiY = 38;
  float sliderW = 210;

  ElMainMenu(PFont f, float volAwal) {
    font = f;
    volume = constrain(volAwal, 0, 1);
    tMulai = millis();
    buatVignette();
  }

  // ------------------------------------------------------------------
  // VIGNETTE
  // ------------------------------------------------------------------
  void buatVignette() {
    vig = createImage(width, height, ARGB);
    vig.loadPixels();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        float dx = (x - width * 0.5) / (width * 0.5);
        float dy = (y - height * 0.5) / (height * 0.5);
        float d = sqrt(dx * dx + dy * dy) / 1.414;
        float a = constrain(map(d, 0.25, 1.0, 0, 220), 0, 220);
        vig.pixels[y * width + x] = color(0, 0, 0, a);
      }
    }

    vig.updatePixels();
  }

  // ------------------------------------------------------------------
  // POSISI UI
  // ------------------------------------------------------------------
  float panelW() {
    return min(340, width * 0.43);
  }

  float panelH() {
    return 330;
  }

  float playX() {
    return uiX + 20;
  }

  float playY() {
    return uiY + 226;
  }

  float sliderX0() {
    return uiX + 22;
  }

  float sliderX1() {
    return sliderX0() + sliderW;
  }

  float sliderY() {
    return uiY + 294;
  }

  boolean overPlay() {
    return mouseX >= uiX + 12 &&
           mouseX <= uiX + panelW() - 12 &&
           mouseY >= playY() - 22 &&
           mouseY <= playY() + 20;
  }

  boolean overVol() {
    return mouseX >= sliderX0() - 8 &&
           mouseX <= sliderX1() + 48 &&
           mouseY >= sliderY() - 18 &&
           mouseY <= sliderY() + 18;
  }

  // ------------------------------------------------------------------
  // INPUT
  // ------------------------------------------------------------------
  void tekanPlay() {
    if (memudar) return;
    memudar = true;
    tPlay = millis();
  }

  // Kembalikan menu ke state awal supaya bisa ditampilkan lagi.
  // Volume sengaja TIDAK direset — pilihan user terakhir tetap dipakai.
  void reset() {
    selesai = false;
    memudar = false;
    dragging = false;
    tMulai = millis();
    tPlay = 0;
    mx = 0;
    my = 0;
    hPlay = 0;
    hVol = 0;
  }

  void setVolDariMouse() {
    volume = constrain((mouseX - sliderX0()) / sliderW, 0, 1);
  }

  void mousePressed() {
    if (memudar) return;

    if (overPlay()) {
      tekanPlay();
    } else if (overVol()) {
      dragging = true;
      setVolDariMouse();
    }
  }

  void mouseDragged() {
    if (dragging && !memudar) setVolDariMouse();
  }

  void mouseReleased() {
    dragging = false;
  }

  // ------------------------------------------------------------------
  // TAMPIL UTAMA
  // ------------------------------------------------------------------
  void show() {
    float t = (millis() - tMulai) / 1000.0;

    // Mouse tracking halus. Nilai kecil menjaga gerakan tetap subtle.
    float tx = (mouseX / (float) width - 0.5) * 2;
    float ty = (mouseY / (float) height - 0.5) * 2;

    mx = lerp(mx, constrain(tx, -1, 1), 0.035);
    my = lerp(my, constrain(ty, -1, 1), 0.035);

    boolean hp = !memudar && overPlay();
    boolean hv = !memudar && (overVol() || dragging);

    hPlay = lerp(hPlay, hp ? 1 : 0, 0.13);
    hVol = lerp(hVol, hv ? 1 : 0, 0.13);

    if (hp || hv) cursor(HAND);
    else cursor(ARROW);

    scene3D(t);

    // Semua UI digambar dalam 2D agar tidak ikut bergerak bersama kamera.
    hint(DISABLE_DEPTH_TEST);
    noLights();
    image(vig, 0, 0, width, height);

    gambarTerminal(t);

    // Fade-in saat menu muncul dan fade-out ketika PLAY ditekan.
    float aIn = 255 * (1 - constrain(t / 1.6, 0, 1));
    float aOut = memudar
      ? 255 * constrain((millis() - tPlay) / 850.0, 0, 1)
      : 0;

    float a = max(aIn, aOut);

    if (a > 0) {
      noStroke();
      fill(0, a);
      rect(0, 0, width, height);
    }

    hint(ENABLE_DEPTH_TEST);

    if (memudar && aOut >= 255) {
      selesai = true;
      cursor(ARROW);
    }
  }

  // ------------------------------------------------------------------
  // TERMINAL UI - KIRI ATAS
  // ------------------------------------------------------------------
  void gambarTerminal(float t) {
    float w = panelW();
    float h = panelH();

    // Panel transparan gelap, bukan kotak solid.
    noStroke();
    fill(8, 8, 5, 174);
    rect(uiX, uiY, w, h, 3);

    // Garis tepi dan aksen terminal.
    noFill();
    stroke(190, 174, 112, 105);
    strokeWeight(1);
    rect(uiX, uiY, w, h, 3);

    stroke(220, 202, 137, 190);
    strokeWeight(2);
    line(uiX, uiY, uiX + 42, uiY);
    line(uiX, uiY, uiX, uiY + 42);
    noStroke();

    textFont(font);
    textAlign(LEFT, CENTER);

    // Header kecil.
    textSize(10);
    fill(190, 178, 135);
    text("L T R  //  ENVIRONMENTAL TERMINAL", uiX + 18, uiY + 19);

    // Indikator status.
    float pulse = 125 + 45 * sin(millis() * 0.003);
    noStroke();
    fill(205, 190, 115, pulse);
    ellipse(uiX + 22, uiY + 49, 6, 6);

    textSize(10);
    fill(177, 168, 128);
    text("SIGNAL DETECTED", uiX + 34, uiY + 49);

    textAlign(RIGHT, CENTER);
    fill(130, 123, 94);
    text("VER 01.00", uiX + w - 17, uiY + 49);

    // Judul utama.
    textAlign(LEFT, CENTER);
    textSize(min(31, w * 0.095));
    fill(0, 150);
    text("LOOPING THE ROOM", uiX + 19 + 1, uiY + 91 + 2);
    fill(231, 218, 169);
    text("LOOPING THE ROOM", uiX + 19, uiY + 91);

    // Deskripsi.
    textSize(10);
    fill(159, 150, 115);
    text("YOU ARE NOT SUPPOSED TO BE HERE.", uiX + 20, uiY + 119);

    // Garis pemisah.
    stroke(160, 145, 91, 105);
    strokeWeight(1);
    line(uiX + 18, uiY + 145, uiX + w - 18, uiY + 145);
    noStroke();

    // Informasi lokasi.
    textSize(9);
    fill(126, 119, 91);
    text("CURRENT LOCATION", uiX + 20, uiY + 165);
    textSize(12);
    fill(207, 194, 145);
    text("LEVEL  0  /  THE LOBBY", uiX + 20, uiY + 184);

    // Tombol PLAY.
    float py = playY();
    if (hPlay > 0.01) {
      noStroke();
      fill(222, 205, 139, 17 * hPlay);
      rect(uiX + 12, py - 18, w - 24, 36, 2);
    }

    stroke(lerpColor(color(115, 105, 72), color(224, 207, 143), hPlay));
    strokeWeight(1);
    line(uiX + 18, py + 20, uiX + w - 18, py + 20);
    noStroke();

    textAlign(LEFT, CENTER);
    textSize(15);
    fill(lerpColor(color(178, 168, 128), color(255, 238, 178), hPlay));
    text(">  ENTER THE ROOM", uiX + 21, py);

    // VOLUME.
    textSize(9);
    fill(160, 150, 112);
    text("AUDIO OUTPUT", uiX + 20, uiY + 265);

    textAlign(RIGHT, CENTER);
    fill(205, 193, 150);
    text(nf(round(volume * 100), 3) + "%", uiX + w - 20, uiY + 265);

    // Slider.
    float x0 = sliderX0();
    float x1 = sliderX1();
    float sy = sliderY();
    float knob = x0 + volume * sliderW;

    stroke(91, 84, 58, 210);
    strokeWeight(2);
    line(x0, sy, x1, sy);

    stroke(213, 197, 139, 220);
    strokeWeight(2);
    line(x0, sy, knob, sy);

    noStroke();
    fill(225, 209, 151, 35 + 45 * hVol);
    ellipse(knob, sy, 16 + 5 * hVol, 16 + 5 * hVol);
    fill(231, 216, 164);
    ellipse(knob, sy, 6, 6);

    // Footer.
    textAlign(LEFT, CENTER);
    textSize(8);
    fill(111, 105, 82);
    text("ESCAPE IS NOT GUARANTEED", uiX + 20, uiY + h - 13);

    // Jam berjalan kecil pada header terminal.
    textAlign(RIGHT, CENTER);
    fill(116, 109, 83);
    text("SYS " + nf((int)(t * 10) % 10000, 4),
         uiX + w - 18, uiY + h - 13);
  }

  // ------------------------------------------------------------------
  // LATAR 3D
  // ------------------------------------------------------------------
  void scene3D(float t) {
    PGraphics g = cv.begin();

    g.background(5, 4, 2);
    g.noStroke();
    g.noLights();
    g.perspective(radians(70), (float)g.width / g.height, 10, 6000);

    // Kamera maju perlahan. Respons mouse dibatasi agar tidak berlebihan.
    float camZ = -t * 28;
    float idleX = sin(t * 0.32) * 5;
    float idleY = sin(t * 0.48) * 2.5;

    float ox = mx * 24 + idleX;
    float oy = my * 13 + idleY;

    float targetX = mx * 95;
    float targetY = my * 48;

    g.camera(
      ox, oy, camZ,
      targetX, targetY, camZ - 1000,
      0, 1, 0
    );

    float zBase = camZ + 100;          // kontinu
    int n = (int)(FAR / STEP);

    // Lantai & plafon.
    strip(g, camZ, zBase, n,
          -HALLW, FLOOR, HALLW, FLOOR, 77, 65, 43);

    strip(g, camZ, zBase, n,
          -HALLW, CEIL, HALLW, CEIL, 125, 115, 82);

    // Dinding: stripWall dengan gradient vertikal tipis (pseudo-AO).
    stripWall(g, camZ, zBase, n, -HALLW, 177, 163, 111);
    stripWall(g, camZ, zBase, n,  HALLW, 166, 152, 101);

    // Detail dinding.
    detailWallpaper(g, camZ);
    detailBaseboard(g, camZ);
    detailCarpet(g, camZ);

    // Lampu plafon.
    detailLampu(g, camZ);

    // Pilar.
    int kp = (int)floor(camZ / 450.0) + 1;
    for (int k = kp; k > kp - 11; k--) {
      pilar(g, camZ, -380, k * 450);
      pilar(g, camZ,  380, k * 450 + 225);
    }

    // Debu.
    detailDebu(g, camZ, t);

    cv.end();
  }

  // ------------------------------------------------------------------
  // DETAIL WALLPAPER  (v3 - semua world-fixed)
  // ------------------------------------------------------------------
  void detailWallpaper(PGraphics g, float camZ) {
    int awal = (int)floor(camZ / 600.0) + 1;

    // --- Seam horizontal tiap 600 unit (world-fixed) ---
    for (int k = awal; k > awal - 9; k--) {
      float z = k * 600;
      float dist = abs(z - camZ);
      if (dist > FOG_END) continue;

      color c = fogCol(110, 98, 63, dist, 0.85);
      g.stroke(c);
      g.strokeWeight(2);

      g.line(-HALLW + 2, CEIL + 8, z,
             -HALLW + 2, FLOOR - 8, z);
      g.line(HALLW - 2, CEIL + 8, z,
             HALLW - 2, FLOOR - 8, z);
      g.noStroke();
    }

    // --- Garis vertikal tipis tiap 125 unit (world-fixed) ---
    // Sebelumnya: z = camZ + 150 - i*125  (mengikuti kamera -> "nabrak")
    // Sekarang : snap ke grid world 125 unit
    int jumlah = 40;
    int startGrid = (int)floor((camZ + 200) / 125.0);
    for (int i = 0; i < jumlah; i++) {
      float z = (startGrid - i) * 125.0;
      float dist = abs(z - camZ);
      if (dist > FOG_END * 0.9) continue;

      color c = fogCol(135, 119, 76, dist, 0.72);
      g.stroke(c);
      g.strokeWeight(1);

      g.line(-HALLW + 1, CEIL + 5, z,
             -HALLW + 1, FLOOR - 5, z);
      g.line(HALLW - 1, CEIL + 5, z,
             HALLW - 1, FLOOR - 5, z);
      g.noStroke();
    }

    // --- Panel/lekukan dinding tiap 600 unit (world-fixed) ---
    for (int k = awal; k > awal - 7; k--) {
      float z = k * 600 - 300;
      float dist = abs(z - camZ);
      if (dist > FOG_END) continue;

      color gelap  = fogCol(115, 103, 69, dist, 0.75);
      color terang = fogCol(193, 178, 123, dist, 0.8);

      // Sisi kiri.
      quad4(g, gelap,
            -HALLW + 3, CEIL + 15, z,
            -HALLW + 3, FLOOR - 35, z,
            -HALLW + 3, FLOOR - 35, z - 5,
            -HALLW + 3, CEIL + 15, z - 5);

      g.stroke(terang);
      g.strokeWeight(1);
      g.line(-HALLW + 4, CEIL + 18, z - 10,
             -HALLW + 4, FLOOR - 38, z - 10);
      g.noStroke();

      // Sisi kanan.
      quad4(g, gelap,
            HALLW - 3, CEIL + 15, z,
            HALLW - 3, FLOOR - 35, z,
            HALLW - 3, FLOOR - 35, z - 5,
            HALLW - 3, CEIL + 15, z - 5);
    }
  }

  // ------------------------------------------------------------------
  // BASEBOARD
  // ------------------------------------------------------------------
  void detailBaseboard(PGraphics g, float camZ) {
    float zBase = camZ + 100;

    g.strokeWeight(1);
    for (int i = 0; i < 86; i++) {
      float z = zBase - i * STEP;
      color c = fogCol(210, 203, 178, abs(z - camZ), 0.9);
      g.stroke(c);

      g.line(-HALLW + 1, FLOOR - 25, z,
             -HALLW + 1, FLOOR - 3, z);
      g.line(HALLW - 1, FLOOR - 25, z,
             HALLW - 1, FLOOR - 3, z);
    }
    g.noStroke();
  }

  // ------------------------------------------------------------------
  // TEKSTUR KARPET PROSEDURAL (world-fixed)
  // ------------------------------------------------------------------
  void detailCarpet(PGraphics g, float camZ) {
    int tileSpacing = 48;
    int startTile = (int)floor((camZ - 100) / tileSpacing);
    int maxTiles = 90;

    for (int t = 0; t < maxTiles; t++) {
      int tileIdx = startTile - t;
      float z = tileIdx * (float)tileSpacing;
      float dist = abs(z - camZ);
      if (dist > FOG_END * 0.85) continue;

      for (int j = 0; j < 3; j++) {
        int seed = tileIdx * 3 + j;
        float x = map(noise(seed * 13.17), 0, 1, -HALLW + 35, HALLW - 35);
        float s = 2 + noise(seed * 4.7) * 5;
        float shade = 48 + noise(seed * 2.3) * 28;
        color c = fogCol(shade, shade * 0.84, shade * 0.58, dist, 0.9);

        g.fill(c);
        g.beginShape();
        g.vertex(x,     FLOOR - 1.5, z);
        g.vertex(x + s, FLOOR - 1.5, z);
        g.vertex(x + s, FLOOR - 1.5, z - s);
        g.vertex(x,     FLOOR - 1.5, z - s);
        g.endShape(CLOSE);
      }
    }

    g.strokeWeight(1);
    for (int i = 0; i < 36; i++) {
      float x = -HALLW + i * 50;
      color c = fogCol(93, 78, 52, 500, 0.45);
      g.stroke(c);
      g.line(x,      FLOOR - 1, camZ + 100,
             x + 12, FLOOR - 1, camZ - 1800);
    }
    g.noStroke();
  }

  // ------------------------------------------------------------------
  // LAMPU FLUORESCENT (v3 - lampu terlihat jelas)
  // ------------------------------------------------------------------
  void detailLampu(PGraphics g, float camZ) {
    int kz = (int)floor(camZ / 300.0) + 1;
    int jml = (int)(FAR / 300.0) + 2;
    float[] px = { -540, -180, 180, 540 };

    for (int k = kz; k > kz - jml; k--) {
      float zl = k * 300;
      float dist = abs(zl - camZ);
      if (dist > FOG_END) continue;

      float flick = 0.94 + 0.06 * noise(k * 0.73, millis() * 0.0007);
      color frame = fogCol(100, 94, 67, dist, 0.9);
      color lamp  = fogCol(255, 250, 225, dist, 1.35 * flick);

      for (int i = 0; i < px.length; i++) {
        float x = px[i];

        // Frame luar: sedikit di bawah plafon (lebih dekat kamera)
        quad4(g, frame,
              x - 88, CEIL + 1.2, zl - 88,
              x + 88, CEIL + 1.2, zl - 88,
              x + 88, CEIL + 1.2, zl + 88,
              x - 88, CEIL + 1.2, zl + 88);

        // Permukaan lampu: lebih rendah (lebih dekat kamera) -> selalu terlihat
        quad4(g, lamp,
              x - 73, CEIL + 2.0, zl - 73,
              x + 73, CEIL + 2.0, zl - 73,
              x + 73, CEIL + 2.0, zl + 73,
              x - 73, CEIL + 2.0, zl + 73);

        // Garis pemisah panel.
        g.stroke(fogCol(190, 184, 155, dist, 0.9));
        g.strokeWeight(2);
        g.line(x, CEIL + 1.0, zl - 70, x, CEIL + 1.0, zl + 70);
        g.noStroke();
      }
    }
  }

  // ------------------------------------------------------------------
  // DEBU DI UDARA
  // ------------------------------------------------------------------
  void detailDebu(PGraphics g, float camZ, float t) {
    g.strokeWeight(1);

    for (int i = 0; i < 95; i++) {
      float x = map(noise(i * 8.31), 0, 1, -500, 500);
      float y = map(noise(i * 3.71), 0, 1, CEIL + 25, FLOOR - 35);
      float z = camZ - 150 - (i * 43 % 2100);

      x += sin(t * 0.28 + i) * 6;
      y += sin(t * 0.20 + i * 0.7) * 3;

      float dist = abs(z - camZ);
      color c = fogCol(220, 207, 160, dist, 0.55);
      g.stroke(c);
      g.point(x, y, z);
    }
    g.noStroke();
  }

  // ------------------------------------------------------------------
  // PENCAHAYAAN (v3 - kontras lampu pulih)
  // ------------------------------------------------------------------
  float lightF(float z) {
    // half-wave: 1 di tengah lampu, 0 di antara lampu
    float c = cos(z * TWO_PI / 300.0);
    float s = constrain(c, 0, 1);

    // smootherstep: transisi halus, tidak ada knee
    float e = s * s * s * (s * (s * 6 - 15) + 10);

    // range asli dipertahankan: 0.72 .. 1.10
    return 0.72 + 0.38 * e;
  }

  color fogCol(float r, float gg, float b, float dist, float lf) {
    float k = constrain(1 - dist / FOG_END, 0, 1);
    // smootherstep pada falloff kabut
    k = k * k * k * (k * (k * 6 - 15) + 10);

    float m = k * lf;

    return color(
      constrain(r  * m + 6 * (1 - k), 0, 255),
      constrain(gg * m + 5 * (1 - k), 0, 255),
      constrain(b  * m + 3 * (1 - k), 0, 255)
    );
  }

  // ------------------------------------------------------------------
  // STRIP GEOMETRI MEMANJANG (datar)
  // ------------------------------------------------------------------
  void strip(PGraphics g, float camZ, float zBase, int n,
             float ax, float ay, float bx, float by,
             float r, float gg, float b) {
    g.beginShape(QUAD_STRIP);

    for (int i = 0; i <= n; i++) {
      float z = zBase - i * STEP;
      g.fill(fogCol(r, gg, b, abs(z - camZ), lightF(z)));
      g.vertex(ax, ay, z);
      g.vertex(bx, by, z);
    }

    g.endShape();
  }

  // ------------------------------------------------------------------
  // STRIP DINDING DENGAN GRADIENT VERTIKAL (pseudo-AO)
  // Terang di dekat plafon, sedikit meredup ke lantai.
  // ------------------------------------------------------------------
  void stripWall(PGraphics g, float camZ, float zBase, int n,
                 float x, float r, float gg, float b) {
    g.noStroke();

    int bands = 6;
    for (int bIdx = 0; bIdx < bands; bIdx++) {
      float t1 = bIdx       / (float)bands;
      float t2 = (bIdx + 1) / (float)bands;

      float y1 = lerp(CEIL, FLOOR, t1);
      float y2 = lerp(CEIL, FLOOR, t2);

      float tMid = (t1 + t2) * 0.5;
      float ao = 0.75 + 0.25 * (1 - tMid);   // terang di atas, redup di bawah

      g.beginShape(QUAD_STRIP);
      for (int i = 0; i <= n; i++) {
        float z = zBase - i * STEP;
        float lf = lightF(z);
        float dist = abs(z - camZ);
        g.fill(fogCol(r * ao, gg * ao, b * ao, dist, lf));
        g.vertex(x, y1, z);
        g.vertex(x, y2, z);
      }
      g.endShape();
    }
  }

  // ------------------------------------------------------------------
  // QUAD 3D
  // ------------------------------------------------------------------
  void quad4(PGraphics g, color c,
             float x1, float y1, float z1,
             float x2, float y2, float z2,
             float x3, float y3, float z3,
             float x4, float y4, float z4) {
    g.fill(c);
    g.beginShape();
    g.vertex(x1, y1, z1);
    g.vertex(x2, y2, z2);
    g.vertex(x3, y3, z3);
    g.vertex(x4, y4, z4);
    g.endShape(CLOSE);
  }

  // ------------------------------------------------------------------
  // PILAR KOTAK DENGAN ALAS
  // ------------------------------------------------------------------
  void pilar(PGraphics g, float camZ, float x, float z) {
    float dist = abs(z - camZ);
    if (z > camZ + 200) return;

    float lf = lightF(z);
    float dir = (x < 0) ? 1 : -1;

    float w  = 65;
    float bw = 75;
    float bh = 26;
    float xi = x + dir * w;
    float xb = x + dir * bw;

    quad4(g, fogCol(205, 193, 145, dist, lf),
          x - w, CEIL,  z + w,
          x + w, CEIL,  z + w,
          x + w, FLOOR, z + w,
          x - w, FLOOR, z + w);

    quad4(g, fogCol(145, 134, 96, dist, lf),
          xi, CEIL,  z - w,
          xi, CEIL,  z + w,
          xi, FLOOR, z + w,
          xi, FLOOR, z - w);

    quad4(g, fogCol(225, 219, 197, dist, lf),
          x - bw, FLOOR - bh, z + bw,
          x + bw, FLOOR - bh, z + bw,
          x + bw, FLOOR,      z + bw,
          x - bw, FLOOR,      z + bw);

    quad4(g, fogCol(175, 168, 148, dist, lf),
          xb, FLOOR - bh, z - bw,
          xb, FLOOR - bh, z + bw,
          xb, FLOOR,      z + bw,
          xb, FLOOR,      z - bw);

    g.stroke(fogCol(105, 97, 68, dist, lf));
    g.strokeWeight(1);
    g.line(x - 35, CEIL + 12, z + w + 1,
           x - 35, FLOOR - 35, z + w + 1);
    g.line(x + 35, CEIL + 12, z + w + 1,
           x + 35, FLOOR - 35, z + w + 1);
    g.noStroke();
  }
}