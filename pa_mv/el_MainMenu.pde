// =====================================================================
//  el_MainMenu.pde
//  MAIN MENU - BACKROOMS 3D + MOUSE PARALLAX + UI TERMINAL
//
//  Panel UI:
//    kiri atas   : terminal utama (ENTER THE ROOM + slider volume), diskala S
//    kiri bawah  : CONTROLS
//    kanan atas  : TEAM (nama kelompok + NIM)
//    kanan bawah : GRAFIKA KOMPUTER
//
//  Pemakaian di pa_mv.pde:
//    menu = new ElMainMenu(fontJepang, VOLUME);
//    menu.show();                 // di draw()
//    menu.selesai                 // true setelah fade-out PLAY selesai
//    void mousePressed()  { if (!menu.selesai) { menu.mousePressed(); return; } }
//    void mouseDragged()  { if (!menu.selesai) menu.mouseDragged(); }
//    void mouseReleased() { if (!menu.selesai) menu.mouseReleased(); }
// =====================================================================

class ElMainMenu {
  // ------------------------- DUNIA 3D -------------------------------
  final float FLOOR = 150;     // y lantai
  final float CEIL  = -110;    // y plafon
  final float HALLW = 900;     // setengah lebar lorong
  final float STEP  = 50;      // jarak segmen sepanjang z
  final float FOG_END = 4200;  // jarak kabut maksimum
  final float FAR   = 4300;    // jarak pandang kamera

  Canvas3D cv = new Canvas3D();   // kanvas offscreen 3D
  PFont font;
  PImage vig;                     // tekstur vignette layar

  float volume;                   // volume saat ini (0..1)
  boolean selesai = false;        // true setelah fade-out PLAY selesai
  boolean memudar = false;        // true selama fade-out
  boolean dragging = false;       // true saat slider volume sedang di-drag

  int tMulai;                     // waktu menu mulai (untuk fade-in & animasi)
  int tPlay;                      // waktu PLAY ditekan (untuk fade-out)

  // Posisi mouse yang sudah dihaluskan (-1..1)
  float mx = 0;
  float my = 0;

  float hPlay = 0;                // hover PLAY (0..1)
  float hVol  = 0;                // hover volume (0..1)

  // ------------------------- UI TERMINAL ----------------------------
  float S = 1.3;                  // skala panel utama
  final float PAD = 20;           // margin kiri-kanan di dalam panel
  float uiX = 42;                 // posisi X panel utama
  float uiY = 38;                 // posisi Y panel utama
  float sliderW = 210;            // lebar slider volume (satuan dasar, sebelum dikali S)

  ElMainMenu(PFont f, float volAwal) {
    font = f;
    volume = constrain(volAwal, 0, 1);
    tMulai = millis();
    buatVignette();
  }

  // ------------------------------------------------------------------
  // VIGNETTE: gradasi hitam di tepi layar
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
  // POSISI UI (sudah dikali S, dipakai untuk deteksi mouse & layout)
  // ------------------------------------------------------------------
  float panelWBase() { return min(340, width * 0.43); }
  float panelW()     { return panelWBase() * S; }
  float panelH()     { return 330 * S; }
  float playY()      { return uiY + 226 * S; }
  float sliderX0()   { return uiX + PAD * S; }
  float sliderX1()   { return sliderX0() + sliderW * S; }
  float sliderY()    { return uiY + 294 * S; }

  boolean overPlay() {
    return mouseX >= uiX + 12 * S &&
           mouseX <= uiX + panelW() - 12 * S &&
           mouseY >= playY() - 22 * S &&
           mouseY <= playY() + 20 * S;
  }

  boolean overVol() {
    return mouseX >= sliderX0() - 8 * S &&
           mouseX <= sliderX1() + 48 * S &&
           mouseY >= sliderY() - 18 * S &&
           mouseY <= sliderY() + 18 * S;
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
  // Volume sengaja TIDAK direset - pilihan user terakhir tetap dipakai.
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
    volume = constrain((mouseX - sliderX0()) / (sliderW * S), 0, 1);
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
    float t = (millis() - tMulai) / 1000.0;   // detik sejak menu muncul

    // Mouse tracking halus (lerp lambat = gerakan subtle)
    float tx = (mouseX / (float) width - 0.5) * 2;
    float ty = (mouseY / (float) height - 0.5) * 2;

    mx = lerp(mx, constrain(tx, -1, 1), 0.035);
    my = lerp(my, constrain(ty, -1, 1), 0.035);

    boolean hp = !memudar && overPlay();
    boolean hv = !memudar && (overVol() || dragging);

    hPlay = lerp(hPlay, hp ? 1 : 0, 0.13);
    hVol  = lerp(hVol,  hv ? 1 : 0, 0.13);

    if (hp || hv) cursor(HAND);
    else cursor(ARROW);

    scene3D(t);

    // Semua UI digambar dalam 2D agar tidak ikut bergerak bersama kamera
    hint(DISABLE_DEPTH_TEST);
    noLights();
    image(vig, 0, 0, width, height);

    gambarTerminal(t);   // kiri atas
    gambarKontrol(t);    // kiri bawah
    gambarTim(t);        // kanan atas
    gambarMatkul(t);     // kanan bawah

    // Fade-in saat menu muncul & fade-out ketika PLAY ditekan
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
  // HELPER PANEL (gaya terminal seragam).
  // `corner`: 0 = kiri atas, 1 = kanan atas, 2 = kiri bawah, 3 = kanan bawah
  // ------------------------------------------------------------------
  void panelDasar(float x, float y, float w, float h, int corner) {
    noStroke();
    fill(8, 8, 5, 174);
    rect(x, y, w, h, 3);

    noFill();
    stroke(190, 174, 112, 105);
    strokeWeight(1);
    rect(x, y, w, h, 3);

    // aksen sudut (garis emas tebal)
    stroke(220, 202, 137, 190);
    strokeWeight(2);
    if (corner == 0) {
      line(x, y, x + 42, y);
      line(x, y, x, y + 42);
    } else if (corner == 1) {
      line(x + w, y, x + w - 42, y);
      line(x + w, y, x + w, y + 42);
    } else if (corner == 2) {
      line(x, y + h, x + 42, y + h);
      line(x, y + h, x, y + h - 42);
    } else {
      line(x + w, y + h, x + w - 42, y + h);
      line(x + w, y + h, x + w, y + h - 42);
    }
    noStroke();
  }

  // ------------------------------------------------------------------
  // TERMINAL UI - KIRI ATAS (digambar dalam satuan dasar, lalu diskala S)
  // ------------------------------------------------------------------
  void gambarTerminal(float t) {
    float w = panelWBase();
    float h = 330;

    pushMatrix();
    translate(uiX, uiY);
    scale(S);
    // mulai dari sini koordinat lokal: (0,0) = pojok kiri atas panel

    panelDasar(0, 0, w, h, 0);

    textFont(font);
    textAlign(LEFT, CENTER);

    // Header kecil
    textSize(10);
    fill(190, 178, 135);
    text("L T R  //  ENVIRONMENTAL TERMINAL", PAD, 19);

    // Indikator status
    float pulse = 125 + 45 * sin(millis() * 0.003);
    noStroke();
    fill(205, 190, 115, pulse);
    ellipse(PAD + 3, 49, 6, 6);

    textSize(10);
    fill(177, 168, 128);
    text("SIGNAL DETECTED", PAD + 15, 49);

    textAlign(RIGHT, CENTER);
    fill(130, 123, 94);
    text("VER 01.00", w - PAD, 49);

    // Judul utama
    textAlign(LEFT, CENTER);
    textSize(min(31, w * 0.095));
    fill(0, 150);
    text("LOOPING THE ROOM", PAD + 1, 91 + 2);   // bayangan judul
    fill(231, 218, 169);
    text("LOOPING THE ROOM", PAD, 91);

    // Deskripsi
    textSize(10);
    fill(159, 150, 115);
    text("YOU ARE NOT SUPPOSED TO BE HERE.", PAD, 119);

    // Garis pemisah
    stroke(160, 145, 91, 105);
    strokeWeight(1);
    line(PAD, 145, w - PAD, 145);
    noStroke();

    // Info lokasi
    textSize(9);
    fill(126, 119, 91);
    text("CURRENT LOCATION", PAD, 165);
    textSize(12);
    fill(207, 194, 145);
    text("LEVEL  0  /  THE LOBBY", PAD, 184);

    // Tombol PLAY
    float py = 226;
    if (hPlay > 0.01) {
      noStroke();
      fill(222, 205, 139, 17 * hPlay);
      rect(12, py - 18, w - 24, 36, 2);
    }

    stroke(lerpColor(color(115, 105, 72), color(224, 207, 143), hPlay));
    strokeWeight(1);
    line(PAD, py + 20, w - PAD, py + 20);
    noStroke();

    textAlign(LEFT, CENTER);
    textSize(15);
    fill(lerpColor(color(178, 168, 128), color(255, 238, 178), hPlay));
    text(">  ENTER THE ROOM", PAD, py);

    // VOLUME
    textSize(9);
    fill(160, 150, 112);
    text("AUDIO OUTPUT", PAD, 265);

    textAlign(RIGHT, CENTER);
    fill(205, 193, 150);
    text(nf(round(volume * 100), 3) + "%", w - PAD, 265);

    // Slider volume
    float x0 = PAD;
    float x1 = PAD + sliderW;
    float sy = 294;
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

    // Footer
    textAlign(LEFT, CENTER);
    textSize(8);
    fill(111, 105, 82);
    text("ESCAPE IS NOT GUARANTEED", PAD, h - 13);

    textAlign(RIGHT, CENTER);
    fill(116, 109, 83);
    text("SYS " + nf((int)(t * 10) % 10000, 4), w - PAD, h - 13);

    popMatrix();
  }

  // ------------------------------------------------------------------
  // INFO KONTROL - KIRI BAWAH
  // ------------------------------------------------------------------
  void gambarKontrol(float t) {
    String[] tombol = { "R", "C", "ESC" };
    String[] fungsi = { "RESTART", "CHECKPOINT", "BACK TO MENU" };

    float w     = panelW();
    float rowH  = 22;
    float headH = 34;
    float h     = headH + tombol.length * rowH + 16;
    float x     = uiX;
    float y     = height - uiY - h;

    panelDasar(x, y, w, h, 2);

    textFont(font);

    // Header
    textAlign(LEFT, CENTER);
    textSize(10);
    fill(190, 178, 135);
    text("C O N T R O L S", x + PAD, y + 18);

    // Garis pemisah
    stroke(160, 145, 91, 105);
    strokeWeight(1);
    line(x + PAD, y + headH - 2, x + w - PAD, y + headH - 2);
    noStroke();

    // Baris kontrol: [ TOMBOL ]  FUNGSI
    for (int i = 0; i < tombol.length; i++) {
      float ry = y + headH + 8 + i * rowH + rowH * 0.5;

      float kw = 40, kh = 16;
      noFill();
      stroke(190, 174, 112, 150);
      strokeWeight(1);
      rect(x + PAD, ry - kh / 2, kw, kh, 2);
      noStroke();

      textAlign(CENTER, CENTER);
      textSize(9);
      fill(231, 218, 169);
      text(tombol[i], x + PAD + kw / 2, ry - 1);

      textAlign(LEFT, CENTER);
      textSize(10);
      fill(177, 168, 128);
      text(fungsi[i], x + PAD + kw + 14, ry - 1);
    }
  }

  // ------------------------------------------------------------------
  // NAMA KELOMPOK + NIM - KANAN ATAS
  // ------------------------------------------------------------------
  void gambarTim(float t) {
    String namaKel = "IWAK HARUAN MASAK HABANG";
    String[] nim  = { "2409106028", "2409106034", "2409106039", "2409106044" };
    String[] nama = { "Dwi Prasetyawan", "M. Naufal Rifyan Ilham", "M. Rizal Alfath", "Rangga Aditya Rahman" };

    float rowH  = 22;
    float headH = 34;
    float kelH  = 40;
    float w     = 340;
    float h     = headH + kelH + nim.length * rowH + 16;
    float x     = width - uiX - w;
    float y     = uiY;

    panelDasar(x, y, w, h, 1);

    textFont(font);

    // Header
    textAlign(LEFT, CENTER);
    textSize(10);
    fill(190, 178, 135);
    text("T E A M  //  OPERATORS", x + PAD, y + 18);

    stroke(160, 145, 91, 105);
    strokeWeight(1);
    line(x + PAD, y + headH - 2, x + w - PAD, y + headH - 2);
    noStroke();

    // Nama kelompok
    textSize(min(15, (w - PAD * 2) / 17.0));
    fill(0, 150);
    text(namaKel, x + PAD + 1, y + headH + 20 + 1);
    fill(231, 218, 169);
    text(namaKel, x + PAD, y + headH + 20);

    stroke(160, 145, 91, 70);
    strokeWeight(1);
    line(x + PAD, y + headH + kelH - 2, x + w - PAD, y + headH + kelH - 2);
    noStroke();

    // Daftar anggota: NIM (kiri) + nama
    for (int i = 0; i < nim.length; i++) {
      float ry = y + headH + kelH + 4 + i * rowH + rowH * 0.5;

      textAlign(LEFT, CENTER);
      textSize(10);
      fill(140, 131, 98);
      text(nim[i], x + PAD, ry);

      fill(207, 194, 145);
      text(nama[i], x + PAD + 86, ry);
    }
  }

  // ------------------------------------------------------------------
  // PANEL KECIL - KANAN BAWAH
  // ------------------------------------------------------------------
  void gambarMatkul(float t) {
    String teks = "GRAFIKA KOMPUTER";

    textFont(font);
    textSize(13);
    float w = textWidth(teks) + PAD * 2;
    float h = 40;
    float x = width - uiX - w;
    float y = height - uiY - h;

    panelDasar(x, y, w, h, 3);

    textAlign(CENTER, CENTER);
    fill(231, 218, 169);
    text(teks, x + w / 2, y + h / 2 - 1);
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

    // Kamera maju perlahan + respon mouse dibatasi agar tidak berlebihan
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

    float zBase = camZ + 100;
    int n = (int)(FAR / STEP);

    // Lantai & plafon
    strip(g, camZ, zBase, n, -HALLW, FLOOR, HALLW, FLOOR, 77, 65, 43);
    strip(g, camZ, zBase, n, -HALLW, CEIL, HALLW, CEIL, 125, 115, 82);

    // Dinding dengan gradient vertikal tipis (pseudo-AO)
    stripWall(g, camZ, zBase, n, -HALLW, 177, 163, 111);
    stripWall(g, camZ, zBase, n,  HALLW, 166, 152, 101);

    // Detail dinding
    detailWallpaper(g, camZ);
    detailBaseboard(g, camZ);
    detailCarpet(g, camZ);

    // Lampu plafon
    detailLampu(g, camZ);

    // Pilar
    int kp = (int)floor(camZ / 450.0) + 1;
    for (int k = kp; k > kp - 11; k--) {
      pilar(g, camZ, -380, k * 450);
      pilar(g, camZ,  380, k * 450 + 225);
    }

    // Debu
    detailDebu(g, camZ, t);

    cv.end();
  }

  // ------------------------------------------------------------------
  // DETAIL WALLPAPER (semua world-fixed)
  // ------------------------------------------------------------------
  void detailWallpaper(PGraphics g, float camZ) {
    int awal = (int)floor(camZ / 600.0) + 1;

    // Seam tiap 600 unit
    for (int k = awal; k > awal - 9; k--) {
      float z = k * 600;
      float dist = abs(z - camZ);
      if (dist > FOG_END) continue;

      color c = fogCol(110, 98, 63, dist, 0.85);
      g.stroke(c);
      g.strokeWeight(2);

      g.line(-HALLW + 2, CEIL + 8, z, -HALLW + 2, FLOOR - 8, z);
      g.line(HALLW - 2, CEIL + 8, z,  HALLW - 2, FLOOR - 8, z);
      g.noStroke();
    }

    // Garis vertikal tipis tiap 125 unit
    int jumlah = 40;
    int startGrid = (int)floor((camZ + 200) / 125.0);
    for (int i = 0; i < jumlah; i++) {
      float z = (startGrid - i) * 125.0;
      float dist = abs(z - camZ);
      if (dist > FOG_END * 0.9) continue;

      color c = fogCol(135, 119, 76, dist, 0.72);
      g.stroke(c);
      g.strokeWeight(1);

      g.line(-HALLW + 1, CEIL + 5, z, -HALLW + 1, FLOOR - 5, z);
      g.line(HALLW - 1, CEIL + 5, z,  HALLW - 1, FLOOR - 5, z);
      g.noStroke();
    }

    // Panel/lekukan dinding tiap 600 unit
    for (int k = awal; k > awal - 7; k--) {
      float z = k * 600 - 300;
      float dist = abs(z - camZ);
      if (dist > FOG_END) continue;

      color gelap  = fogCol(115, 103, 69, dist, 0.75);
      color terang = fogCol(193, 178, 123, dist, 0.8);

      // Sisi kiri
      quad4(g, gelap,
            -HALLW + 3, CEIL + 15, z,
            -HALLW + 3, FLOOR - 35, z,
            -HALLW + 3, FLOOR - 35, z - 5,
            -HALLW + 3, CEIL + 15, z - 5);

      g.stroke(terang);
      g.strokeWeight(1);
      g.line(-HALLW + 4, CEIL + 18, z - 10, -HALLW + 4, FLOOR - 38, z - 10);
      g.noStroke();

      // Sisi kanan
      quad4(g, gelap,
            HALLW - 3, CEIL + 15, z,
            HALLW - 3, FLOOR - 35, z,
            HALLW - 3, FLOOR - 35, z - 5,
            HALLW - 3, CEIL + 15, z - 5);
    }
  }

  // ------------------------------------------------------------------
  // BASEBOARD (garis plint bawah dinding)
  // ------------------------------------------------------------------
  void detailBaseboard(PGraphics g, float camZ) {
    float zBase = camZ + 100;

    g.strokeWeight(1);
    for (int i = 0; i < 86; i++) {
      float z = zBase - i * STEP;
      color c = fogCol(210, 203, 178, abs(z - camZ), 0.9);
      g.stroke(c);

      g.line(-HALLW + 1, FLOOR - 25, z, -HALLW + 1, FLOOR - 3, z);
      g.line(HALLW - 1, FLOOR - 25, z,  HALLW - 1, FLOOR - 3, z);
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
      g.line(x, FLOOR - 1, camZ + 100, x + 12, FLOOR - 1, camZ - 1800);
    }
    g.noStroke();
  }

  // ------------------------------------------------------------------
  // LAMPU FLUORESCENT
  // ------------------------------------------------------------------
  void detailLampu(PGraphics g, float camZ) {
    int kz = (int)floor(camZ / 300.0) + 1;
    int jml = (int)(FAR / 300.0) + 2;
    float[] px = { -540, -180, 180, 540 };   // posisi X 4 lampu per baris

    for (int k = kz; k > kz - jml; k--) {
      float zl = k * 300;
      float dist = abs(zl - camZ);
      if (dist > FOG_END) continue;

      float flick = 0.94 + 0.06 * noise(k * 0.73, millis() * 0.0007);   // kedip halus
      color frame = fogCol(100, 94, 67, dist, 0.9);
      color lamp  = fogCol(255, 250, 225, dist, 1.35 * flick);

      for (int i = 0; i < px.length; i++) {
        float x = px[i];

        // Frame luar
        quad4(g, frame,
              x - 88, CEIL + 1.2, zl - 88,
              x + 88, CEIL + 1.2, zl - 88,
              x + 88, CEIL + 1.2, zl + 88,
              x - 88, CEIL + 1.2, zl + 88);

        // Permukaan lampu
        quad4(g, lamp,
              x - 73, CEIL + 2.0, zl - 73,
              x + 73, CEIL + 2.0, zl - 73,
              x + 73, CEIL + 2.0, zl + 73,
              x - 73, CEIL + 2.0, zl + 73);

        // Garis pemisah panel
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
  // PENCAHAYAAN
  // ------------------------------------------------------------------
  // Kekuatan cahaya sebagai fungsi z (fluktuasi dengan periode 300 unit)
  float lightF(float z) {
    float c = cos(z * TWO_PI / 300.0);
    float s = constrain(c, 0, 1);
    float e = s * s * s * (s * (s * 6 - 15) + 10);   // smoothstep di sisi atas
    return 0.72 + 0.38 * e;
  }

  // Warna dengan kabut jarak & faktor cahaya
  color fogCol(float r, float gg, float b, float dist, float lf) {
    float k = constrain(1 - dist / FOG_END, 0, 1);
    k = k * k * k * (k * (k * 6 - 15) + 10);          // smoothstep

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
  // ------------------------------------------------------------------
  void stripWall(PGraphics g, float camZ, float zBase, int n,
                 float x, float r, float gg, float b) {
    g.noStroke();

    int bands = 6;                           // jumlah pita vertikal
    for (int bIdx = 0; bIdx < bands; bIdx++) {
      float t1 = bIdx       / (float)bands;
      float t2 = (bIdx + 1) / (float)bands;

      float y1 = lerp(CEIL, FLOOR, t1);
      float y2 = lerp(CEIL, FLOOR, t2);

      float tMid = (t1 + t2) * 0.5;
      float ao = 0.75 + 0.25 * (1 - tMid);   // makin dekat lantai makin gelap

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
    float dir = (x < 0) ? 1 : -1;               // arah menghadap ke tengah

    float w  = 65;                              // setengah lebar pilar
    float bw = 75;                              // setengah lebar alas
    float bh = 26;                              // tinggi alas
    float xi = x + dir * w;                     // sisi dalam pilar
    float xb = x + dir * bw;                    // sisi luar alas

    // sisi depan
    quad4(g, fogCol(205, 193, 145, dist, lf),
          x - w, CEIL,  z + w,
          x + w, CEIL,  z + w,
          x + w, FLOOR, z + w,
          x - w, FLOOR, z + w);

    // sisi dalam (menghadap lorong)
    quad4(g, fogCol(145, 134, 96, dist, lf),
          xi, CEIL,  z - w,
          xi, CEIL,  z + w,
          xi, FLOOR, z + w,
          xi, FLOOR, z - w);

    // alas atas
    quad4(g, fogCol(225, 219, 197, dist, lf),
          x - bw, FLOOR - bh, z + bw,
          x + bw, FLOOR - bh, z + bw,
          x + bw, FLOOR,      z + bw,
          x - bw, FLOOR,      z + bw);

    // alas sisi luar
    quad4(g, fogCol(175, 168, 148, dist, lf),
          xb, FLOOR - bh, z - bw,
          xb, FLOOR - bh, z + bw,
          xb, FLOOR,      z + bw,
          xb, FLOOR,      z - bw);

    // garis vertikal dekoratif di sisi depan
    g.stroke(fogCol(105, 97, 68, dist, lf));
    g.strokeWeight(1);
    g.line(x - 35, CEIL + 12, z + w + 1, x - 35, FLOOR - 35, z + w + 1);
    g.line(x + 35, CEIL + 12, z + w + 1, x + 35, FLOOR - 35, z + w + 1);
    g.noStroke();
  }
}