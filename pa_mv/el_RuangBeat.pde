// =====================================================================
//  el_RuangBeat.pde   [ELEMENT 3D - LATAR]   beat 297 -> 328
//  16 ruangan Backrooms BERBEDA, kamera hampir diam (dorong maju pelan
//  + hentakan FOV tiap beat). Memakai mesin pencahayaan ElBackroomStatic
//  (class ini turunannya), jadi lampu titik berwarna + kabut + vignette sama.
//
//  Daftar ruangan (indeks):
//    0  Poolrooms (kolam ubin)        8  Koridor neon
//    1  Lorong hotel merah            9  Kamar mandi ubin
//    2  Kantor kubikel               10  Perpustakaan
//    3  Garasi parkir beton          11  Kamar anak (lampu tidur)
//    4  Koridor sekolah + loker      12  Aula pilar gelap
//    5  Ruang tamu 70-an + TV        13  Lobi lift marmer
//    6  Ruang bola ungu + perosotan  14  Ruang putih, pintu merah
//    7  Gudang rak tak berujung      15  Level 0 kuning besar (ruang penutup)
//
//  Pemakaian:
//    ruangBeat = new ElRuangBeat();
//    ruangBeat.show(clock, 297, 312, 328);
//      beat mulai..akhirGanti : ruang 0..14 berurutan
//      beat akhirGanti..akhir : 16 ruangan urutan lain (mulai dari ruang 15)
// =====================================================================
class ElRuangBeat extends ElBackroomStatic {
  final int JUMLAH = 16;    // jumlah ruangan tersedia
  float tb = 0;             // salinan beatPos (dipakai di fungsi ruangan)
  float vigK = 1.0;         // kekuatan vignette
  boolean tempel = true;    // false = hasil 3D TIDAK ditempel ke layar (dipakai ElRuangTV)

  ElRuangBeat() {
    lampX = new float[24]; lampY = new float[24]; lampZ = new float[24];
    lampI = new float[24]; lampRad = new float[24];
    lampR = new float[24]; lampG = new float[24]; lampB = new float[24];
    kedip = 0.35;           // kekuatan kedip lampu per beat
  }

  // Wrapper: tambahkan lampu selama kapasitas array masih cukup
  void addLamp(float x, float y, float z, float inten, float rad, float r, float gr, float b) {
    if (nL >= lampX.length) return;
    super.addLamp(x, y, z, inten, rad, r, gr, b);
  }

  // ------------------------------------------------------------------
  // Jadwal ruangan:
  //   beat mulai..akhirGanti-1 : ruang 0..14 berurutan
  //   beat akhirGanti..akhir-1 : ganti tiap beat, urutan `urut` (ruang 15 di depan)
  // ------------------------------------------------------------------
  void show(BeatClock t, int mulai, int akhirGanti, int akhir) {
    int[] urut = { 15, 7, 12, 1, 9, 4, 13, 0, 10, 5, 14, 2, 8, 11, 3, 6 };
    int idx = (t.beat < akhirGanti) ? t.beat - mulai : urut[(t.beat - akhirGanti) % urut.length];
    showRuang(t, idx, t.frac, 70);
  }

  // Render satu ruangan berdasarkan indeks.
  // `u` = progres dalam beat (0..1), `dolly` = dorong maju kamera (px).
  void showRuang(BeatClock t, int idx, float u, float dolly) {
    g = cv.begin();
    nL = 0;
    tb = t.beatPos;
    vigK = 0.8;
    pulse = 1 + kedip * pow(1 - t.frac, 4);   // denyut kecil tiap beat
    float punch = pow(1 - t.frac, 3);

    g.background(0);
    g.noLights();
    g.noStroke();
    g.perspective(radians(62) - punch * 0.04, (float) g.width / g.height, 5, 4300);
    float zc = -dolly * u;                    // posisi kamera sepanjang z
    float sx = sin(tb * 0.7) * 5, sy = sin(tb * 1.1 + 1) * 3;   // goyang kamera halus
    g.camera(sx, sy, zc,   sx * 0.4, 25 + sy, zc - 1000,   0, 1, 0);

    gelap = 0.95;
    int r = ((idx % JUMLAH) + JUMLAH) % JUMLAH;
    switch (r) {
      case 0:  roomPool();     break;
      case 1:  roomHotel();    break;
      case 2:  roomKantor();   break;
      case 3:  roomParkir();   break;
      case 4:  roomSekolah();  break;
      case 5:  roomTamu();     break;
      case 6:  roomBola();     break;
      case 7:  roomGudang();   break;
      case 8:  roomNeon();     break;
      case 9:  roomToilet();   break;
      case 10: roomPerpus();   break;
      case 11: roomAnak();     break;
      case 12: roomAula();     break;
      case 13: roomLobiLift(); break;
      case 14: roomPutih();    break;
      default: roomFinal();    break;
    }
    vig(vigK);
    if (tempel) cv.end(); else cv.pg.endDraw();
  }

  // =====================================================================
  //  PEMBANTU
  // =====================================================================
  // Kalikan warna dengan faktor k (clamp ke 0..255)
  color mulc(color c, float k) {
    return color(constrain(red(c) * k, 0, 255), constrain(green(c) * k, 0, 255), constrain(blue(c) * k, 0, 255));
  }

  // Interpolasi linear dua warna
  color mixc(color a, color b, float t) {
    return color(lerp(red(a), red(b), t), lerp(green(a), green(b), t), lerp(blue(a), blue(b), t));
  }

  // Warna emisif ikut kabut jarak
  color fogc(color c, float z) {
    return mulc(c, pulse * (1 - 0.6 * constrain((-z - 300) / 2400.0f, 0, 1)));
  }

  // Bidang tegak menghadap kamera (z tetap)
  void qZ(color c, float sh, int nu, int nv, float x0, float x1, float y0, float y1, float z) {
    quadN(c, sh, nu, nv, x0, y0, z, x1, y0, z, x1, y1, z, x0, y1, z);
  }

  // Bidang tegak di samping (x tetap), memanjang di z
  void qX(color c, float sh, int nu, int nv, float x, float y0, float y1, float z0, float z1) {
    quadN(c, sh, nu, nv, x, y0, z0, x, y0, z1, x, y1, z1, x, y1, z0);
  }

  // Bidang datar (y tetap)
  void qY(color c, float sh, int nu, int nv, float y, float x0, float x1, float z0, float z1) {
    quadN(c, sh, nu, nv, x0, y, z0, x1, y, z0, x1, y, z1, x0, y, z1);
  }

  // Balok (z0 = sisi jauh, z1 = sisi dekat, y0 = atas)
  void boxN(color c, float x0, float x1, float y0, float y1, float z0, float z1, int nu, int nv) {
    qZ(c, 1.0, nu, nv, x0, x1, y0, y1, z1);
    qX(c, 0.62, nu, nv, x0, y0, y1, z0, z1);
    qX(c, 0.78, nu, nv, x1, y0, y1, z0, z1);
    qY(c, 1.0, nu, nu, y0, x0, x1, z0, z1);
    qY(c, 0.5, 1, 1, y1, x0, x1, z0, z1);
  }

  // ---- mode batch: satu beginShape untuk banyak quad (lebih ringan) ----
  void bBegin() { g.beginShape(QUADS); }
  void bEnd()   { g.endShape(); }

  void bQ(color c, float sh, float x1, float y1, float z1, float x2, float y2, float z2,
          float x3, float y3, float z3, float x4, float y4, float z4) {
    v(c, sh, x1, y1, z1); v(c, sh, x2, y2, z2); v(c, sh, x3, y3, z3); v(c, sh, x4, y4, z4);
  }

  // Petak lantai
  void bTileY(color c, float y, float x0, float x1, float z0, float z1) {
    bQ(c, 1.0, x0, y, z0, x1, y, z0, x1, y, z1, x0, y, z1);
  }

  // Balok dengan `nv` pita vertikal (untuk pencahayaan halus)
  void bBox(color c, float x0, float x1, float y0, float y1, float z0, float z1, int nv) {
    for (int i = 0; i < nv; i++) {
      float a = lerp(y0, y1, i / (float) nv), b = lerp(y0, y1, (i + 1) / (float) nv);
      bQ(c, 1.0,  x0, a, z1, x1, a, z1, x1, b, z1, x0, b, z1);
      bQ(c, 0.62, x0, a, z0, x0, a, z1, x0, b, z1, x0, b, z0);
      bQ(c, 0.78, x1, a, z0, x1, a, z1, x1, b, z1, x1, b, z0);
    }
    bQ(c, 1.0, x0, y0, z0, x1, y0, z0, x1, y0, z1, x0, y0, z1);
  }

  // Garis berpencahayaan (dipecah supaya cahaya halus)
  void ln(color c, float sh, float x1, float y1, float z1, float x2, float y2, float z2, float w) {
    float L = dist(x1, y1, z1, x2, y2, z2);
    int n = max(1, (int) ceil(L / 220.0f));
    g.strokeWeight(w);
    for (int i = 0; i < n; i++) {
      float a = i / (float) n, b = (i + 1) / (float) n;
      float ax = lerp(x1, x2, a), ay = lerp(y1, y2, a), az = lerp(z1, z2, a);
      float bx = lerp(x1, x2, b), by = lerp(y1, y2, b), bz = lerp(z1, z2, b);
      g.stroke(lit(c, sh, (ax + bx) / 2, (ay + by) / 2, (az + bz) / 2));
      g.line(ax, ay, az, bx, by, bz);
    }
    g.noStroke();
  }

  // Bola low-poly
  void ball(float cx, float cy, float cz, float r, color c) {
    int ns = 7, nt = 4;
    for (int j = 0; j < nt; j++) {
      float p0 = -HALF_PI + PI * j / nt, p1 = -HALF_PI + PI * (j + 1) / nt;
      float sh = 0.45 + 0.55 * max(0, -sin((p0 + p1) / 2));   // shading berdasarkan lintang
      for (int i = 0; i < ns; i++) {
        float a0 = TWO_PI * i / ns, a1 = TWO_PI * (i + 1) / ns;
        v(c, sh, cx + r * cos(p0) * cos(a0), cy + r * sin(p0), cz + r * cos(p0) * sin(a0));
        v(c, sh, cx + r * cos(p0) * cos(a1), cy + r * sin(p0), cz + r * cos(p0) * sin(a1));
        v(c, sh, cx + r * cos(p1) * cos(a1), cy + r * sin(p1), cz + r * cos(p1) * sin(a1));
        v(c, sh, cx + r * cos(p1) * cos(a0), cy + r * sin(p1), cz + r * cos(p1) * sin(a0));
      }
    }
  }

  // Quad emisif (tidak kena lampu) + kabut
  void em(color c, float x1, float y1, float z1, float x2, float y2, float z2,
          float x3, float y3, float z3, float x4, float y4, float z4) {
    quadFlat(fogc(c, (z1 + z3) / 2), x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4);
  }
  void emZ(color c, float x0, float x1, float y0, float y1, float z) { em(c, x0, y0, z, x1, y0, z, x1, y1, z, x0, y1, z); }
  void emY(color c, float y, float x0, float x1, float z0, float z1)   { em(c, x0, y, z0, x1, y, z0, x1, y, z1, x0, y, z1); }
  void emX(color c, float x, float y0, float y1, float z0, float z1)   { em(c, x, y0, z0, x, y0, z1, x, y1, z1, x, y1, z0); }

  // Vignette 2D: gelap di tepi, terang di tengah
  void vig(float k) {
    g.camera();
    g.perspective();
    g.hint(DISABLE_DEPTH_TEST);
    float cx = g.width / 2.0f, cy = g.height / 2.0f;
    float rr = dist(0, 0, cx, cy) * 1.05f;
    g.noStroke();
    g.beginShape(TRIANGLE_FAN);
    g.fill(0, 0);
    g.vertex(cx, cy, 0);
    for (int i = 0; i <= 32; i++) {
      float a = TWO_PI * i / 32;
      g.fill(0, 215 * k);
      g.vertex(cx + cos(a) * rr, cy + sin(a) * rr, 0);
    }
    g.endShape();
    g.hint(ENABLE_DEPTH_TEST);
  }

  // =====================================================================
  //  0  POOLROOMS
  // =====================================================================
  void roomPool() {
    fl = 130; ce = -175; wx = 520; zb = -2600; amb = 0.16; gelap = 0.55; vigK = 0.7;
    float ledge = 150, hL = 26;
    for (int i = 0; i < 6; i++) addLamp((i % 2 == 0) ? -150 : 150, ce + 15, -250 - i * 430, 0.9, 560, 0.85, 1.0, 1.0);
    addLamp(0, fl - 40, zb + 150, 1.6, 600, 1.0, 0.95, 0.8);
    color tile = color(214, 236, 236), tileD = color(160, 205, 210), water = color(66, 186, 204), joint = color(110, 160, 172);

    qY(water, 1.0, 14, 30, fl, -wx + ledge, wx - ledge, 0, zb);
    qY(water, 1.0, 2, 3, fl, -140, 140, zb, zb - 80);
    qY(tile, 1.0, 3, 30, fl - hL, -wx, -wx + ledge, 0, zb);
    qY(tile, 1.0, 3, 30, fl - hL, wx - ledge, wx, 0, zb);
    qX(tileD, 0.8, 30, 1, -wx + ledge, fl - hL, fl, 0, zb);
    qX(tileD, 0.7, 30, 1, wx - ledge, fl - hL, fl, 0, zb);
    qX(tile, 0.85, 30, 5, -wx, ce, fl - hL, 0, zb);
    qX(tile, 0.75, 30, 5, wx, ce, fl - hL, 0, zb);
    qY(color(150, 172, 176), 0.9, 10, 30, ce, -wx, wx, 0, zb);

    for (int k = 1; k < 6; k++) {
      float y = ce + k * (fl - hL - ce) / 6.0f;
      ln(joint, 0.8, -wx + 1, y, 0, -wx + 1, y, zb, 1);
      ln(joint, 0.7, wx - 1, y, 0, wx - 1, y, zb, 1);
    }
    for (float z = -20; z > zb; z -= 60) {
      ln(joint, 0.8, -wx + 1, ce, z, -wx + 1, fl - hL, z, 1);
      ln(joint, 0.7, wx - 1, ce, z, wx - 1, fl - hL, z, 1);
    }
    for (int i = 1; i <= 5; i++) {
      float z = -i * 430 - 100;
      for (int s = -1; s <= 1; s += 2) boxN(tile, s * 250 - 36, s * 250 + 36, ce, fl, z - 36, z + 36, 2, 5);
      boxN(tileD, -wx + ledge, wx - ledge, ce, ce + 34, z - 22, z + 22, 12, 1);
      panel(0, z + 215, 100, 40, color(255, 255, 250));
    }
    archWall(tile, tileD, zb, 70, -wx, wx, ce, fl, 0, 130, fl - 150, 14);
    quadFlat4(color(255, 248, 225), color(255, 248, 225), color(255, 232, 190), color(255, 232, 190),
              -140, ce, zb - 74, 140, ce, zb - 74, 140, fl, zb - 74, -140, fl, zb - 74);
    for (int i = 0; i < 70; i++) {
      float x = -wx + ledge + 30 + rnd(i, 1) * (2 * (wx - ledge) - 60);
      float z = -40 - rnd(i, 2) * (-zb - 80);
      float s = 10 + rnd(i, 3) * 20, o = sin(tb * 1.5 + i) * 6;
      em(color(150, 230, 238), x - s + o, fl - 1.2, z, x + o, fl - 1.2, z - s * 0.5, x + s + o, fl - 1.2, z, x + o, fl - 1.2, z + s * 0.5);
    }
  }

  // =====================================================================
  //  1  HOTEL MERAH
  // =====================================================================
  void roomHotel() {
    fl = 130; ce = -120; wx = 200; zb = -2800; amb = 0.16; gelap = 0.8; vigK = 0.9;
    for (int i = 0; i < 7; i++) addLamp((i % 2 == 0 ? -1 : 1) * (wx - 25), -30, -300 - i * 380, 1.5, 340, 1.0, 0.72, 0.4);
    addLamp(0, -20, zb + 100, 1.0, 500, 0.6, 0.7, 1.0);
    color wood = color(80, 44, 26), gold = color(190, 150, 60);
    shell(color(112, 22, 30), color(62, 40, 36), color(124, 40, 46), color(70, 26, 30));
    qY(color(34, 78, 56), 1.0, 2, 30, fl - 0.8, -62, 62, 0, zb);
    qY(gold, 1.0, 1, 30, fl - 1.0, -70, -64, 0, zb);
    qY(gold, 1.0, 1, 30, fl - 1.0, 64, 70, 0, zb);
    qX(wood, 0.8, 30, 2, -wx + 0.6, fl - 95, fl, 0, zb);
    qX(wood, 0.7, 30, 2, wx - 0.6, fl - 95, fl, 0, zb);
    qX(gold, 0.8, 30, 1, -wx + 0.8, fl - 99, fl - 93, 0, zb);
    qX(gold, 0.7, 30, 1, wx - 0.8, fl - 99, fl - 93, 0, zb);
    bBegin();
    for (float z = -12; z > zb; z -= 40) {
      bQ(color(150, 60, 66), 0.8, -wx + 1, ce, z, -wx + 1, ce, z - 10, -wx + 1, fl - 99, z - 10, -wx + 1, fl - 99, z);
      bQ(color(150, 60, 66), 0.7, wx - 1, ce, z, wx - 1, ce, z - 10, wx - 1, fl - 99, z - 10, wx - 1, fl - 99, z);
    }
    bEnd();
    for (int i = 0; i < 7; i++) {
      for (int s = -1; s <= 1; s += 2) {
        float z0 = -230 - i * 380 - (s > 0 ? 190 : 0);
        float x = s * (wx - 1.5);
        qX(color(40, 22, 14), 0.8, 1, 1, x, fl - 172, fl, z0 + 6, z0 - 100);
        qX(wood, 0.8, 2, 4, x - s * 0.5, fl - 165, fl, z0, z0 - 94);
        em(color(220, 180, 80), x - s * 1.5, fl - 135, z0 - 40, x - s * 1.5, fl - 135, z0 - 54, x - s * 1.5, fl - 125, z0 - 54, x - s * 1.5, fl - 125, z0 - 40);
        float zl = -300 - i * 380;
        if ((i % 2 == 0) == (s < 0)) {
          em(color(255, 214, 140), x - s * 2, -48, zl - 12, x - s * 2, -48, zl + 12, x - s * 2, -14, zl + 12, x - s * 2, -14, zl - 12);
        }
      }
    }
    emZ(color(150, 180, 235), -42, 42, -70, 20, zb + 1);
    qZ(color(30, 20, 18), 0.8, 1, 1, -50, -42, -78, 28, zb + 1.2);
    qZ(color(30, 20, 18), 0.8, 1, 1, 42, 50, -78, 28, zb + 1.2);
  }

  // =====================================================================
  //  2  KANTOR KUBIKEL
  // =====================================================================
  void roomKantor() {
    fl = 130; ce = -95; wx = 950; zb = -2400; amb = 0.12; gelap = 0.5; vigK = 0.8;
    for (int c = -1; c <= 1; c++) for (int r = 0; r < 4; r++) addLamp(c * 500, ce + 12, -350 - r * 480, 0.6, 540, 0.9, 1.0, 1.0);
    addLamp(wx - 60, -20, -700, 1.0, 700, 0.7, 0.85, 1.0);
    shell(color(84, 96, 108), color(128, 132, 128), color(176, 170, 148), color(150, 146, 130));
    for (int c = -1; c <= 1; c++) for (int r = 0; r < 4; r++) panel(c * 500, -350 - r * 480, 130, 55, color(235, 250, 245));
    for (int k = 0; k < 3; k++) emX(color(205, 225, 250), wx - 1, -50, 40, -300 - k * 700, -560 - k * 700);
    g.strokeWeight(1);
    for (float x = -wx + 200; x < wx; x += 200) ln(color(120, 124, 118), 0.9, x, ce + 0.5, 0, x, ce + 0.5, zb, 1);
    for (float z = -150; z > zb; z -= 200) ln(color(120, 124, 118), 0.9, -wx, ce + 0.5, z, wx, ce + 0.5, z, 1);
    color fab = color(62, 112, 120), desk = color(150, 124, 92), dark = color(30, 32, 36);
    float[] xs = { -780, -400, 400, 780 };
    for (int a = 0; a < 4; a++) {
      for (int k = 0; k < 5; k++) {
        float xc = xs[a], zc = -520 - k * 380;
        boolean left = xc < 0;
        float inner = left ? xc + 100 : xc - 100;
        boxN(fab, xc - 100, xc + 100, fl - 118, fl - 4, zc - 110, zc - 104, 1, 1);
        boxN(fab, (left ? xc - 104 : xc + 98), (left ? xc - 98 : xc + 104), fl - 118, fl - 4, zc - 110, zc + 110, 1, 1);
        boxN(desk, xc - 100, xc + 100, fl - 64, fl - 58, zc - 104, zc - 20, 3, 1);
        boxN(dark, xc - 18, xc + 18, fl - 98, fl - 64, zc - 70, zc - 62, 1, 1);
        float sx = left ? xc + 90 : xc - 90;
        emZ(color(120, 160, 215), xc - 15, xc + 15, fl - 94, fl - 68, zc - 61.5);
        boxN(color(40, 42, 50), xc - 24, xc + 24, fl - 52, fl - 44, zc + 10, zc + 52, 1, 1);
        boxN(color(40, 42, 50), xc - 24, xc + 24, fl - 90, fl - 52, zc + 48, zc + 54, 1, 1);
      }
    }
  }

  // =====================================================================
  //  3  GARASI PARKIR
  // =====================================================================
  void roomParkir() {
    fl = 130; ce = -70; wx = 1100; zb = -3200; amb = 0.11; gelap = 0.55; vigK = 0.85;
    for (int i = 0; i < 8; i++) addLamp((i % 2 == 0 ? -330 : 330), ce + 14, -300 - i * 400, 1.6, 620, 1.0, 0.62, 0.26);
    addLamp(wx - 120, -20, zb + 80, 0.9, 400, 0.3, 1.0, 0.5);
    color conc = color(98, 98, 94);
    shell(color(90, 90, 88), color(78, 78, 76), conc, color(84, 84, 82));
    qY(color(190, 188, 178), 1, 1, 1, fl - 0.8, -1100, 1100, 0, 0);
    bBegin();
    for (float z = -120; z > zb; z -= 170) {
      bTileY(color(190, 188, 176), fl - 0.9, -820, -330, z, z - 5);
      bTileY(color(190, 188, 176), fl - 0.9, 330, 820, z, z - 5);
    }
    for (float z = -60; z > zb; z -= 220) bTileY(color(200, 170, 30), fl - 0.9, -3, 3, z, z - 90);
    bEnd();
    for (int i = 1; i <= 5; i++) {
      float z = -i * 600;
      for (int s = -1; s <= 1; s += 2) {
        float x = s * 330;
        boxN(conc, x - 40, x + 40, ce, fl, z - 40, z + 40, 2, 4);
        bBegin();
        for (int k = 0; k < 6; k++) {
          color hc = (k % 2 == 0) ? color(205, 170, 20) : color(25, 25, 22);
          float y0 = fl - 70 + k * 11.6, y1 = y0 + 11.6;
          bQ(hc, 1.0, x - 40.8, y0, z + 40.8, x + 40.8, y0, z + 40.8, x + 40.8, y1, z + 40.8, x - 40.8, y1, z + 40.8);
          bQ(hc, 0.7, x - 40.8, y0, z - 40.8, x - 40.8, y0, z + 40.8, x - 40.8, y1, z + 40.8, x - 40.8, y1, z - 40.8);
          bQ(hc, 0.8, x + 40.8, y0, z - 40.8, x + 40.8, y0, z + 40.8, x + 40.8, y1, z + 40.8, x + 40.8, y1, z - 40.8);
        }
        bEnd();
      }
    }
    for (float z = -400; z > zb; z -= 600) boxN(color(84, 84, 80), -wx, wx, ce, ce + 28, z - 30, z + 30, 22, 1);
    for (int p = -2; p <= 2; p++) {
      if (p == 0) continue;
      float x = p * 310;
      for (int i = 0; i < 30; i++) {
        float za = -i * 107, zb2 = -(i + 1) * 107;
        boxN(color(60, 62, 66), x - 7, x + 7, ce + 4, ce + 20, zb2, za, 1, 1);
      }
    }
    float[][] cars = { { -560, -1150, 0 }, { 600, -1750, 1 }, { -580, -2350, 2 }, { 560, -900, 3 } };
    color[] cc = { color(40, 60, 112), color(130, 34, 34), color(110, 112, 114), color(40, 90, 70) };
    for (int i = 0; i < cars.length; i++) {
      float cx = cars[i][0], cz = cars[i][1]; color c = cc[(int) cars[i][2]];
      boxN(c, cx - 115, cx + 115, fl - 38, fl - 10, cz - 50, cz + 50, 3, 1);
      boxN(mulc(c, 0.8), cx - 55, cx + 50, fl - 62, fl - 38, cz - 44, cz + 44, 2, 1);
      emZ(color(50, 70, 90), cx - 50, cx + 45, fl - 58, fl - 42, cz + 44.5);
      for (int w1 = -1; w1 <= 1; w1 += 2) for (int w2 = -1; w2 <= 1; w2 += 2)
        boxN(color(14, 14, 14), cx + w1 * 72 - 16, cx + w1 * 72 + 16, fl - 22, fl, cz + w2 * 46 - 6, cz + w2 * 46 + 6, 1, 1);
    }
    emZ(color(70, 230, 120), wx - 220, wx - 120, -10, 20, zb + 1);
  }

  // =====================================================================
  //  4  KORIDOR SEKOLAH
  // =====================================================================
  void roomSekolah() {
    fl = 130; ce = -110; wx = 280; zb = -3000; amb = 0.14; gelap = 0.42; vigK = 0.85;
    for (int i = 0; i < 8; i++) addLamp(0, ce + 12, -300 - i * 380, 1.0, 520, 1.0, 0.97, 0.85);
    addLamp(0, -30, zb + 80, 2.2, 600, 0.85, 0.92, 1.0);
    shell(color(180, 190, 165), color(140, 138, 122), color(204, 198, 168), color(190, 190, 170));
    for (int i = 0; i < 8; i++) panel(0, -300 - i * 380, 40, 90, color(255, 252, 235));
    bBegin();
    for (int i = 0; i < 10; i++) for (int j = 0; j < 54; j++) {
      color c = ((i + j) % 2 == 0) ? color(176, 196, 168) : color(210, 200, 168);
      bTileY(c, fl - 0.5, -wx + i * 56, -wx + (i + 1) * 56, -j * 56, -(j + 1) * 56);
    }
    bEnd();
    color grn = color(104, 150, 122);
    qX(grn, 0.8, 30, 1, -wx + 0.5, fl - 85, fl, 0, zb);
    qX(grn, 0.7, 30, 1, wx - 0.5, fl - 85, fl, 0, zb);
    qX(color(40, 80, 60), 0.8, 30, 1, -wx + 0.8, fl - 88, fl - 84, 0, zb);
    qX(color(40, 80, 60), 0.7, 30, 1, wx - 0.8, fl - 88, fl - 84, 0, zb);
    bBegin();
    for (int s = -1; s <= 1; s += 2) {
      float x = s * (wx - 2);
      for (int k = 0; k < 45; k++) {
        float z0 = -150 - k * 34;
        color c = mulc(color(70, 102, 146), 0.9 + 0.2 * rnd(k, s + 3));
        bQ(c, s < 0 ? 0.85 : 0.75, x, fl - 152, z0, x, fl - 152, z0 - 33, x, fl, z0 - 33, x, fl, z0);
        bQ(color(25, 35, 50), 0.8, x - s * 0.8, fl - 135, z0 - 8, x - s * 0.8, fl - 135, z0 - 25, x - s * 0.8, fl - 130, z0 - 25, x - s * 0.8, fl - 130, z0 - 8);
        bQ(color(25, 35, 50), 0.8, x - s * 0.8, fl - 125, z0 - 8, x - s * 0.8, fl - 125, z0 - 25, x - s * 0.8, fl - 120, z0 - 25, x - s * 0.8, fl - 120, z0 - 8);
      }
    }
    bEnd();
    for (int k = 0; k < 3; k++) {
      float z0 = -1800 - k * 340;
      qX(color(120, 84, 52), 0.7, 2, 3, wx - 2, fl - 170, fl, z0, z0 - 100);
      emX(color(235, 244, 255), wx - 3, fl - 140, fl - 80, z0 - 20, z0 - 80);
    }
    emZ(color(240, 248, 255), -90, 90, fl - 230, fl - 20, zb + 1);
    ln(color(80, 90, 90), 0.9, 0, fl - 230, zb + 1.5, 0, fl - 20, zb + 1.5, 3);
    ln(color(80, 90, 90), 0.9, -90, fl - 125, zb + 1.5, 90, fl - 125, zb + 1.5, 3);
  }

  // =====================================================================
  //  5  RUANG TAMU 70-AN
  // =====================================================================
  void roomTamu() {
    fl = 130; ce = -115; wx = 400; zb = -1000; amb = 0.15; gelap = 0.75; vigK = 0.9;
    addLamp(-290, -10, -620, 2.0, 420, 1.0, 0.7, 0.35);
    addLamp(0, -40, zb + 140, 1.5, 520, 0.55, 0.75, 1.0);
    addLamp(0, ce + 10, -300, 0.5, 500, 1.0, 0.85, 0.6);
    shell(color(160, 88, 32), color(150, 134, 108), color(108, 68, 38), color(150, 112, 56));
    g.strokeWeight(1);
    for (float z = -20; z > zb; z -= 36) {
      ln(color(60, 34, 18), 0.8, -wx + 1, ce, z, -wx + 1, fl, z, 1);
      ln(color(60, 34, 18), 0.7, wx - 1, ce, z, wx - 1, fl, z, 1);
    }
    for (float x = -wx + 40; x < wx; x += 80) for (float y = ce + 30; y < fl; y += 60) {
      em(color(200, 150, 70), x - 6, y, zb + 1, x, y - 8, zb + 1, x + 6, y, zb + 1, x, y + 8, zb + 1);
    }
    qY(color(120, 40, 30), 1.0, 6, 8, fl - 0.8, -200, 200, -240, -800);
    boxN(color(80, 48, 28), -170, 170, fl - 50, fl, zb, zb + 90, 4, 2);
    boxN(color(38, 34, 32), -110, 110, fl - 135, fl - 50, zb + 20, zb + 90, 3, 2);
    int st = (int) (tb * 8);
    for (int i = 0; i < 9; i++) for (int j = 0; j < 5; j++) {
      float k = 60 + 150 * rnd(i * 7 + j, st);
      float x0 = -96 + i * 21.3, y0 = fl - 128 + j * 15.6;
      emZ(color(k * 0.9, k, k * 1.1), x0, x0 + 21.3, y0, y0 + 15.6, zb + 91);
    }
    sofa(color(176, 126, 30), 0, -470, PI, 300, 110);
    boxN(color(86, 54, 30), -70, 70, fl - 36, fl - 30, -720, -640, 2, 1);
    boxN(color(86, 54, 30), -66, -58, fl - 30, fl, -716, -708, 1, 1);
    boxN(color(86, 54, 30), 58, 66, fl - 30, fl, -716, -708, 1, 1);
    cyl(color(60, 50, 40), -290, -620, 3, fl, 150, 6);
    cyl(color(255, 200, 120), -290, -620, 26, fl - 150, 40, 10);
    qX(color(30, 80, 70), 0.7, 1, 1, -wx + 1.5, fl - 100, fl - 40, -300, -420);
    qX(color(120, 100, 40), 0.7, 1, 1, -wx + 1.6, fl - 92, fl - 48, -312, -408);
    qX(color(170, 60, 40), 0.6, 1, 1, wx - 1.5, fl - 100, fl - 40, -500, -640);
  }

  // =====================================================================
  //  6  RUANG BOLA UNGU
  // =====================================================================
  void roomBola() {
    fl = 130; ce = -190; wx = 620; zb = -1600; amb = 0.18; gelap = 0.72; vigK = 0.75;
    for (int i = 0; i < 4; i++) addLamp((i % 2 == 0 ? -250 : 250), ce + 20, -350 - i * 380, 1.4, 600, 0.92, 0.82, 1.0);
    addLamp(0, -40, zb + 80, 1.2, 500, 1.0, 0.8, 0.5);
    shell(color(70, 46, 104), color(110, 70, 150), color(156, 124, 194), color(140, 108, 180));
    bBegin();
    for (int i = 0; i < 12; i++) for (int j = 0; j < 16; j++) {
      color c = ((i + j) % 2 == 0) ? color(130, 80, 170) : color(80, 44, 116);
      bTileY(c, ce + 1, -wx + i * 103.3f, -wx + (i + 1) * 103.3f, -j * 100, -(j + 1) * 100);
    }
    bEnd();
    float[] bandY = { fl - 120, fl - 100, fl - 80 };
    color[] bandC = { color(230, 190, 60), color(80, 160, 220), color(220, 80, 110) };
    for (int s = 0; s < 3; s++) {
      qX(bandC[s], 0.8, 16, 1, -wx + 0.8, bandY[s], bandY[s] + 14, 0, zb);
      qX(bandC[s], 0.7, 16, 1, wx - 0.8, bandY[s], bandY[s] + 14, 0, zb);
    }
    color[] pal = { color(220, 50, 60), color(240, 200, 50), color(60, 110, 220), color(60, 190, 110), color(240, 120, 180), color(240, 140, 40) };
    g.beginShape(QUADS);
    for (int i = 0; i < 130; i++) {
      float x = -460 + rnd(i, 1) * 920, z = -200 - rnd(i, 2) * 1280, r = 21 + rnd(i, 3) * 6;
      if (x < -420 && z < -700 && z > -1000) continue;
      ball(x, fl - r * (0.45 + 0.4 * rnd(i, 4)), z, r, pal[(int) (rnd(i, 5) * 6) % 6]);
    }
    g.endShape();
    boxN(color(235, 200, 50), -590, -450, ce + 40, fl, -900, -780, 2, 4);
    boxN(color(235, 200, 50), -590, -450, fl - 160, fl - 150, -900, -770, 2, 1);
    quadN(color(210, 50, 56), 0.9, 2, 6, -545, fl - 150, -780, -455, fl - 150, -780, -455, fl - 4, -380, -545, fl - 4, -380);
    boxN(color(210, 50, 56), -551, -545, fl - 170, fl - 8, -780, -380, 1, 6);
    boxN(color(210, 50, 56), -455, -449, fl - 170, fl - 8, -780, -380, 1, 6);
    ring(color(30, 20, 50), 1, 0, fl - 80, zb + 1, 0, 90, 20, 0);
    ring(color(240, 200, 60), 1, 0, fl - 80, zb + 2, 90, 108, 20, 0);
  }

  // =====================================================================
  //  7  GUDANG
  // =====================================================================
  void roomGudang() {
    fl = 130; ce = -200; wx = 900; zb = -3300; amb = 0.08; gelap = 0.55; vigK = 0.9;
    for (int i = 0; i < 7; i++) addLamp((i % 2 == 0) ? -40 : 40, -170, -300 - i * 450, 1.9, 520, 0.85, 0.95, 1.0);
    shell(color(70, 72, 74), color(46, 48, 50), color(84, 86, 88), color(64, 66, 68));
    qY(color(190, 160, 30), 1, 1, 30, fl - 0.8, -112, -104, 0, zb);
    qY(color(190, 160, 30), 1, 1, 30, fl - 0.8, 104, 112, 0, zb);
    for (int i = 0; i < 7; i++) emY(color(235, 245, 255), -170, -30 + ((i % 2 == 0) ? -40 : 40) * 0, 30, -280 - i * 450, -330 - i * 450);
    float[] rows = { -180, -460, 110, 390 };
    color post = color(205, 95, 25), board = color(40, 80, 150);
    color[] box = { color(160, 120, 70), color(140, 104, 62), color(180, 140, 84), color(120, 128, 140) };
    bBegin();
    for (int rI = 0; rI < 4; rI++) {
      float x0 = rows[rI], x1 = x0 + 70;
      for (int k = 0; k < 9; k++) {
        float z1 = -250 - k * 300, z0 = z1 - 290;
        bBox(post, x0, x0 + 6, fl - 300, fl, z1 - 6, z1, 3);
        for (int lv = 0; lv < 4; lv++) {
          float y = fl - 8 - lv * 80;
          bBox(board, x0, x1, y - 5, y, z0, z1, 1);
          if (rnd(rI * 40 + k, lv) > 0.25) {
            float bw = 30 + rnd(k, lv + rI) * 30, bh = 28 + rnd(lv, k + rI) * 20;
            bBox(box[(int) (rnd(k * 3 + rI, lv) * 4) % 4], x0 + 8, x1 - 8, y - 5 - bh, y - 5, z0 + 40, z0 + 40 + bw * 2.5, 1);
            if (rnd(k, lv * 5 + rI) > 0.4) bBox(box[(k + lv) % 4], x0 + 10, x1 - 10, y - 5 - bh * 0.8, y - 5, z0 + 160, z0 + 160 + bw * 2, 1);
          }
        }
      }
    }
    bEnd();
    boxN(color(230, 180, 40), 400, 520, fl - 22, fl, -1100, -980, 2, 1);
    boxN(color(160, 120, 70), 410, 510, fl - 60, fl - 22, -1090, -990, 1, 1);
  }

  // =====================================================================
  //  8  KORIDOR NEON
  // =====================================================================
  void roomNeon() {
    fl = 130; ce = -120; wx = 480; zb = -2400; amb = 0.05; gelap = 1.0; vigK = 0.6;
    for (int i = 0; i < 8; i++) {
      boolean m = i % 2 == 0;
      addLamp(m ? -wx + 60 : wx - 60, -60, -250 - i * 300, 1.3, 440, m ? 1.0 : 0.1, m ? 0.2 : 0.8, m ? 0.7 : 1.0);
    }
    addLamp(0, -10, zb + 120, 1.6, 500, 1.0, 0.2, 0.7);
    shell(color(30, 22, 58), color(22, 16, 40), color(40, 34, 70), color(20, 14, 36));
    color mg = color(255, 50, 170), cy = color(40, 220, 255);
    for (int i = 0; i < 9; i++) {
      float z = -200 - i * 260;
      color c = (i % 2 == 0) ? mg : cy;
      float x0 = -wx + 30, x1 = wx - 30, y0 = ce + 22, y1 = fl - 22, w = 6;
      emY(c, y0, x0, x1, z - w, z + w);
      emY(c, y1, x0, x1, z - w, z + w);
      emX(c, x0, y0, y1, z - w, z + w);
      emX(c, x1, y0, y1, z - w, z + w);
      emY(mulc(c, 0.3), y1 - 0.5, x0, x1, z - 20, z + 20);
    }
    for (float z = -120; z > zb; z -= 120) emY(color(120, 160, 255), fl - 0.8, -4, 4, z, z - 40);
    for (float z = -120; z > zb; z -= 240) {
      emX(color(255, 50, 170), -wx + 1, fl - 6, fl - 2, z, z - 100);
      emX(color(40, 220, 255), wx - 1, fl - 6, fl - 2, z - 120, z - 220);
    }
    ring(color(255, 50, 170), 1, 0, -10, zb + 2, 100, 118, 28, 0);
    ring(color(40, 220, 255), 1, 0, -10, zb + 2, 140, 148, 28, 0);
  }

  // =====================================================================
  //  9  KAMAR MANDI
  // =====================================================================
  void roomToilet() {
    fl = 130; ce = -105; wx = 300; zb = -1900; amb = 0.14; gelap = 0.45; vigK = 0.8;
    for (int i = 0; i < 5; i++) {
      float k = (i == 2 && rnd((int) (tb * 9), 7) < 0.6) ? 0.15 : 1.0;
      addLamp(0, ce + 10, -300 - i * 380, 1.7 * k, 480, 0.85, 1.0, 0.95);
      panel(0, -300 - i * 380, 40, 70, mulc(color(235, 255, 245), k < 1 ? 0.3 : 1));
    }
    shell(color(150, 180, 164), color(200, 214, 204), color(160, 196, 178), color(170, 200, 184));
    bBegin();
    for (int i = 0; i < 12; i++) for (int j = 0; j < 38; j++) {
      color c = ((i + j) % 2 == 0) ? color(222, 230, 224) : color(126, 168, 148);
      bTileY(c, fl - 0.5, -wx + i * 50, -wx + (i + 1) * 50, -j * 50, -(j + 1) * 50);
    }
    bEnd();
    qX(color(60, 112, 92), 0.8, 30, 1, -wx + 0.5, fl - 130, fl - 112, 0, zb);
    qX(color(60, 112, 92), 0.7, 30, 1, wx - 0.5, fl - 130, fl - 112, 0, zb);
    for (float z = -25; z > zb; z -= 50) {
      ln(color(110, 150, 134), 0.8, -wx + 1, ce, z, -wx + 1, fl, z, 1);
      ln(color(110, 150, 134), 0.7, wx - 1, ce, z, wx - 1, fl, z, 1);
    }
    for (int i = 0; i < 9; i++) {
      float z = -250 - i * 150;
      boxN(color(86, 150, 140), -wx, -wx + 130, fl - 150, fl - 20, z - 3, z + 3, 2, 1);
      qX(color(100, 168, 158), 0.8, 3, 3, -wx + 130, fl - 148, fl - 22, z + 6, z + 150 - 6);
      boolean occ = rnd(i, 3) > 0.6;
      emX(occ ? color(220, 50, 40) : color(60, 200, 90), -wx + 129, fl - 96, fl - 90, z + 70, z + 80);
      boxN(color(240, 244, 240), -wx + 18, -wx + 70, fl - 40, fl, z + 60, z + 120, 1, 1);
    }
    for (int i = 0; i < 4; i++) {
      float z = -300 - i * 340;
      boxN(color(220, 228, 224), wx - 70, wx, fl - 88, fl - 78, z - 120, z, 2, 1);
      boxN(color(200, 208, 204), wx - 60, wx - 10, fl - 78, fl, z - 110, z - 10, 1, 1);
      emX(color(40, 50, 52), wx - 30, fl - 90, fl - 88, z - 90, z - 30);
      emX(color(190, 218, 216), wx - 1.5, fl - 175, fl - 105, z - 130, z - 10);
      qX(color(90, 90, 90), 0.8, 1, 1, wx - 1.2, fl - 178, fl - 175, z - 132, z - 8);
      boxN(color(180, 184, 186), wx - 50, wx - 44, fl - 100, fl - 88, z - 70, z - 64, 1, 1);
    }
    disc(color(36, 46, 44), 1, 0, fl - 0.8, -900, 12, 12, 1);
    for (int i = 0; i < 4; i++) emY(color(180, 205, 200), fl - 1, -60, 60, -700 - i * 80, -740 - i * 80);
    emZ(color(210, 235, 225), -70, 70, fl - 190, fl - 130, zb + 1);
  }

  // =====================================================================
  //  10  PERPUSTAKAAN
  // =====================================================================
  void roomPerpus() {
    fl = 130; ce = -200; wx = 520; zb = -2000; amb = 0.12; gelap = 0.85; vigK = 0.9;
    addLamp(0, -120, -900, 2.0, 600, 1.0, 0.8, 0.5);
    addLamp(0, -120, -300, 1.2, 500, 1.0, 0.8, 0.5);
    addLamp(0, -120, -1500, 1.4, 500, 1.0, 0.8, 0.5);
    addLamp(-60, fl - 90, -620, 1.2, 260, 0.4, 1.0, 0.6);
    addLamp(0, -10, zb + 60, 1.0, 600, 0.5, 0.65, 1.0);
    color wood = color(80, 48, 28);
    shell(color(92, 56, 32), color(60, 38, 26), color(70, 44, 28), color(60, 40, 30));
    for (float x = -wx + 30; x < wx; x += 60) ln(color(60, 36, 20), 1.0, x, fl - 0.6, 0, x, fl - 0.6, zb, 1);
    qY(color(120, 36, 40), 1.0, 5, 12, fl - 1.0, -170, 170, -300, -1500);
    qY(color(190, 150, 60), 1.0, 1, 12, fl - 1.2, -176, -170, -300, -1500);
    qY(color(190, 150, 60), 1.0, 1, 12, fl - 1.2, 170, 176, -300, -1500);
    color[] sp = { color(130, 30, 34), color(34, 80, 56), color(60, 40, 28), color(30, 50, 100), color(180, 140, 50), color(90, 40, 80), color(150, 90, 40) };
    for (int s = -1; s <= 1; s += 2) {
      float x = s * (wx - 40);
      qX(wood, 0.7, 20, 1, x, ce + 10, fl, 0, -1900);
      for (int row = 0; row < 5; row++) qY(wood, 0.9, 1, 14, fl - 10 - row * 38, s * wx, x, 0, -1900);
    }
    bBegin();
    for (int s = -1; s <= 1; s += 2) {
      float x = s * (wx - 41);
      for (int row = 0; row < 5; row++) {
        float yb = fl - 10 - row * 38;
        float z = -70;
        int k = 0;
        while (z > -1850) {
          float w = 6 + rnd(k + row * 200, s + 5) * 6, h = 24 + rnd(k, row + 9) * 10;
          bQ(sp[(int) (rnd(k * 7 + row, s + 4) * 7) % 7], 0.9, x, yb - h, z, x, yb - h, z - w, x, yb, z - w, x, yb, z);
          z -= w + 0.8; k++;
        }
      }
    }
    bEnd();
    for (int t2 = 0; t2 < 2; t2++) {
      float zc = -620 - t2 * 700;
      boxN(color(112, 70, 40), -90, 90, fl - 66, fl - 58, zc - 60, zc + 60, 3, 3);
      for (int a = -1; a <= 1; a += 2) for (int b = -1; b <= 1; b += 2)
        boxN(wood, a * 80 - 5, a * 80 + 5, fl - 58, fl, zc + b * 50 - 5, zc + b * 50 + 5, 1, 1);
      boxN(color(30, 110, 70), -66, -54, fl - 90, fl - 66, zc - 6, zc + 6, 1, 1);
      emY(color(150, 255, 190), fl - 88, -64, -56, zc - 5, zc + 5);
    }
    for (int i = 0; i < 7; i++) boxN(wood, -wx + 40, wx - 40, ce, ce + 22, -i * 300 - 40, -i * 300, 10, 1);
    ring(color(210, 160, 70), 1, 0, ce + 70, -900, 56, 68, 14, 1);
    emZ(color(110, 140, 210), -60, 60, -150, 60, zb + 1);
    qZ(color(20, 14, 10), 0.8, 1, 1, -66, -60, -156, 66, zb + 1.2);
    qZ(color(20, 14, 10), 0.8, 1, 1, 60, 66, -156, 66, zb + 1.2);
  }

  // =====================================================================
  //  11  KAMAR ANAK
  // =====================================================================
  void roomAnak() {
    fl = 130; ce = -110; wx = 330; zb = -1100; amb = 0.2; gelap = 0.8; vigK = 0.8;
    addLamp(260, fl - 36, -300, 1.6, 380, 1.0, 0.75, 0.4);
    addLamp(0, -50, zb + 30, 1.1, 650, 0.4, 0.55, 1.0);
    addLamp(0, ce + 12, -500, 0.6, 520, 1.0, 0.9, 0.85);
    shell(color(210, 190, 170), color(210, 205, 215), color(150, 170, 214), color(150, 170, 214));
    qX(color(222, 160, 180), 0.8, 12, 1, -wx + 0.5, fl - 70, fl, 0, zb);
    qX(color(222, 160, 180), 0.7, 12, 1, wx - 0.5, fl - 70, fl, 0, zb);
    color[] pal = { color(220, 70, 70), color(240, 200, 60), color(70, 180, 110), color(70, 120, 220) };
    bBegin();
    for (int i = 0; i < 8; i++) for (int j = 0; j < 13; j++)
      bTileY(pal[(i + j * 2) % 4], fl - 0.8, -280 + i * 70, -280 + (i + 1) * 70 - 2, -100 - j * 70, -100 - (j + 1) * 70 + 2);
    bEnd();
    for (int i = 0; i < 40; i++) {
      float s = 6 + rnd(i, 1) * 6;
      float z = -60 - rnd(i, 2) * 960, y = ce + 10 + rnd(i, 3) * 120;
      int w = (i % 2 == 0) ? 1 : -1;
      color sc = color(255, 235, 140);
      em(sc, w * (wx - 1.5), y - s, z, w * (wx - 1.5), y, z - s * 0.6, w * (wx - 1.5), y + s, z, w * (wx - 1.5), y, z + s * 0.6);
    }
    for (int i = 0; i < 24; i++) {
      float x = -250 + rnd(i, 7) * 500, z = -80 - rnd(i, 8) * 950;
      em(color(190, 255, 190), x - 6, ce + 1.5, z, x, ce + 1.5, z - 6, x + 6, ce + 1.5, z, x, ce + 1.5, z + 6);
    }
    color wd = color(226, 204, 170);
    boxN(wd, 100, 320, fl - 42, fl, -900, -540, 2, 2);
    boxN(color(90, 150, 210), 104, 316, fl - 56, fl - 38, -820, -548, 3, 1);
    boxN(color(244, 240, 230), 130, 290, fl - 66, fl - 54, -896, -850, 2, 1);
    boxN(wd, 100, 320, fl - 100, fl, -906, -898, 2, 2);
    float[][] bl = { { -190, -500, 36 }, { -150, -470, 30 }, { -170, -490, 30 }, { -60, -640, 34 }, { 20, -420, 28 }, { -220, -700, 32 } };
    for (int i = 0; i < bl.length; i++) {
      float x = bl[i][0], z = bl[i][1], s = bl[i][2];
      float yy = (i == 2) ? fl - s * 2 : fl - s;
      boxN(pal[i % 4], x - s / 2, x + s / 2, yy - s, yy, z - s / 2, z + s / 2, 1, 1);
    }
    g.beginShape(QUADS);
    ball(-40, fl - 26, -560, 22, color(150, 100, 60));
    ball(-40, fl - 58, -560, 15, color(150, 100, 60));
    ball(-52, fl - 70, -560, 6, color(130, 84, 48));
    ball(-28, fl - 70, -560, 6, color(130, 84, 48));
    g.endShape();
    emZ(color(110, 140, 214), -75, 75, -110, 10, zb + 1);
    ring(color(250, 245, 210), 1, 30, -85, zb + 2, 0, 18, 14, 0);
    ln(color(255, 255, 255), 1, 0, -110, zb + 1.5, 0, 10, zb + 1.5, 2);
    ln(color(255, 255, 255), 1, -75, -50, zb + 1.5, 75, -50, zb + 1.5, 2);
  }

  // =====================================================================
  //  12  AULA PILAR GELAP
  // =====================================================================
  void roomAula() {
    fl = 130; ce = -240; wx = 1500; zb = -3800; amb = 0.045; gelap = 1.05; vigK = 0.9;
    float[][] lp = { { -420, -500 }, { 420, -900 }, { 0, -1300 }, { -420, -1700 }, { 420, -2100 }, { 0, -2500 }, { -420, -2900 }, { 420, -3300 } };
    for (int i = 0; i < lp.length; i++) {
      addLamp(lp[i][0], -200, lp[i][1], 2.2, 520, 1.0, 0.88, 0.66);
      emY(color(255, 236, 190), -200, lp[i][0] - 30, lp[i][0] + 30, lp[i][1] - 30, lp[i][1] + 30);
    }
    shell(color(50, 52, 60), color(30, 30, 36), color(60, 62, 70), color(40, 40, 46));
    bBegin();
    for (int i = 0; i < 14; i++) for (int j = 0; j < 18; j++) {
      color c = ((i + j) % 2 == 0) ? color(56, 58, 68) : color(40, 42, 50);
      bTileY(c, fl - 0.5, -wx + i * 214.3f, -wx + (i + 1) * 214.3f, -j * 211, -(j + 1) * 211);
    }
    bEnd();
    bBegin();
    for (int a = 0; a < 6; a++) for (int k = 1; k <= 8; k++) {
      float x = -1050 + a * 420, z = -k * 420;
      bBox(color(78, 80, 90), x - 45, x + 45, ce, fl, z - 45, z + 45, 4);
    }
    bEnd();
    for (float z = -300; z > zb; z -= 420) boxN(color(36, 36, 42), -wx, wx, ce, ce + 30, z - 30, z + 30, 24, 1);
    emZ(color(80, 230, 150), -40, 40, fl - 90, fl - 50, zb + 1);
    addLamp(0, fl - 70, zb + 60, 1.0, 300, 0.3, 1.0, 0.6);
  }

  // =====================================================================
  //  13  LOBI LIFT
  // =====================================================================
  void roomLobiLift() {
    fl = 130; ce = -190; wx = 520; zb = -1300; amb = 0.12; gelap = 0.5; vigK = 0.8;
    for (int i = 0; i < 4; i++) addLamp((i % 2 == 0 ? -1 : 1) * (wx - 30), -60, -300 - i * 260, 1.4, 420, 1.0, 0.82, 0.5);
    addLamp(0, -150, zb + 140, 1.6, 520, 1.0, 0.9, 0.7);
    addLamp(0, ce + 10, -500, 0.8, 600, 1.0, 0.9, 0.7);
    shell(color(190, 180, 160), color(176, 160, 130), color(186, 164, 128), color(180, 160, 128));
    bBegin();
    for (int i = 0; i < 8; i++) for (int j = 0; j < 10; j++) {
      color c = ((i + j) % 2 == 0) ? color(210, 200, 180) : color(126, 118, 104);
      bTileY(c, fl - 0.5, -wx + i * 130, -wx + (i + 1) * 130, -j * 130, -(j + 1) * 130);
    }
    bEnd();
    qY(color(176, 140, 60), 1, 1, 10, fl - 0.9, -6, 6, 0, zb);
    color gold = color(170, 138, 66);
    for (int s = -1; s <= 1; s += 2) {
      for (int k = 0; k < 5; k++) {
        float z = -150 - k * 260;
        boxN(gold, s * wx - (s > 0 ? 24 : 0), s * wx + (s < 0 ? 24 : 0), ce, fl, z - 14, z + 14, 1, 4);
      }
      for (int k = 0; k < 4; k++) {
        float z0 = -170 - k * 260;
        qX(color(214, 196, 160), 0.8, 2, 3, s * (wx - 1), ce + 40, fl - 40, z0 - 20, z0 - 230);
        qX(gold, 0.8, 1, 1, s * (wx - 1.5), ce + 36, ce + 42, z0 - 18, z0 - 232);
      }
    }
    boxN(color(70, 56, 34), -150, 150, ce, fl, zb, zb + 14, 4, 4);
    qZ(color(176, 144, 72), 1.0, 2, 4, -72, 0, fl - 200, fl, zb + 15);
    qZ(color(166, 134, 66), 1.0, 2, 4, 0, 72, fl - 200, fl, zb + 15);
    qZ(color(40, 30, 16), 1.0, 1, 1, -1.5, 1.5, fl - 200, fl, zb + 16);
    emZ(color(30, 26, 22), -60, 60, fl - 245, fl - 215, zb + 16);
    emZ(color(255, 60, 40), -6, 6, fl - 238, fl - 222, zb + 17);
    emZ(color(255, 210, 100), 96, 106, fl - 110, fl - 100, zb + 16);
    emZ(color(255, 210, 100), 96, 106, fl - 94, fl - 84, zb + 16);
    emY(color(255, 240, 200), fl - 1, -60, 60, zb + 120, zb + 20);
    for (int s = -1; s <= 1; s += 2) {
      float x = s * 400, z = -1000;
      cyl(color(150, 84, 50), x, z, 24, fl, 40, 8);
      g.beginShape(QUADS);
      ball(x, fl - 62, z, 28, color(44, 120, 60));
      ball(x + 14, fl - 82, z - 8, 22, color(52, 140, 70));
      ball(x - 12, fl - 78, z + 10, 20, color(36, 104, 54));
      g.endShape();
    }
    boxN(color(110, 70, 50), -120, 120, fl - 30, fl - 22, -700, -640, 3, 1);
    boxN(color(90, 56, 40), -116, -108, fl - 22, fl, -696, -684, 1, 1);
    boxN(color(90, 56, 40), 108, 116, fl - 22, fl, -696, -684, 1, 1);
  }

  // =====================================================================
  //  14  RUANG PUTIH, PINTU MERAH
  // =====================================================================
  void roomPutih() {
    fl = 130; ce = -150; wx = 450; zb = -1500; amb = 0.3; gelap = 0.62; vigK = 0.55;
    for (int i = 0; i < 3; i++) { addLamp(0, ce + 12, -300 - i * 450, 1.0, 600, 1.0, 1.0, 1.0); panel(0, -300 - i * 450, 90, 90, color(255)); }
    addLamp(0, fl - 80, zb + 70, 3.2, 900, 1.0, 0.1, 0.06);
    shell(color(232, 232, 236), color(240, 240, 244), color(238, 238, 240), color(232, 232, 236), false);
    bBegin();
    for (float x = -wx; x < wx; x += 90) bQ(color(206, 206, 212), 1.0, x, fl - 0.6, 0, x + 1.5, fl - 0.6, 0, x + 1.5, fl - 0.6, zb, x, fl - 0.6, zb);
    bEnd();
    qZ(color(236, 236, 240), 0.9, 4, 4, -wx, -70, ce, fl, zb);
    qZ(color(236, 236, 240), 0.9, 4, 4, 70, wx, ce, fl, zb);
    qZ(color(236, 236, 240), 0.9, 2, 2, -70, 70, ce, fl - 205, zb);
    for (int s = -1; s <= 1; s += 2) for (int k = 0; k < 3; k++) boxN(color(226, 226, 230), s * 220 - 50, s * 220 + 50, ce, fl, -500 - k * 400 - 50, -500 - k * 400 + 50, 2, 3);
    qZ(color(30, 30, 32), 1, 1, 1, -76, -70, fl - 210, fl, zb + 1);
    qZ(color(30, 30, 32), 1, 1, 1, 70, 76, fl - 210, fl, zb + 1);
    qZ(color(30, 30, 32), 1, 1, 1, -76, 76, fl - 214, fl - 205, zb + 1);
    quadFlat4(color(255, 40, 30), color(255, 40, 30), color(140, 0, 0), color(140, 0, 0),
              -70, fl - 205, zb - 40, 70, fl - 205, zb - 40, 70, fl, zb - 40, -70, fl, zb - 40);
    qX(color(255, 60, 40), 1, 1, 1, -70, fl - 205, fl, zb, zb - 40);
    qX(color(255, 60, 40), 1, 1, 1, 70, fl - 205, fl, zb, zb - 40);
  }

  // =====================================================================
  //  15  LEVEL 0 BESAR  (ruang penutup, ditahan lama)
  // =====================================================================
  void roomFinal() {
    fl = 130; ce = -160; wx = 1000; zb = -3900; amb = 0.08; gelap = 0.5; vigK = 0.75;
    for (int c = -1; c <= 1; c++) for (int r = 0; r < 6; r++) addLamp(c * 500, ce + 14, -300 - r * 450, 0.7, 540, 1.0, 0.96, 0.72);
    addLamp(0, -20, -2990, 0.9, 400, 1.0, 0.3, 0.2);
    color wp = color(152, 132, 52), carpet = color(120, 102, 42);
    shell(carpet, color(128, 122, 94), wp, color(140, 120, 48));
    for (int c = -1; c <= 1; c++) for (int r = 0; r < 6; r++) panel(c * 500, -300 - r * 450, 70, 70, color(255, 250, 215));
    for (int i = 0; i < 26; i++) {
      float x = -wx + 60 + rnd(i, 1) * (2 * wx - 120), z = -80 - rnd(i, 2) * 2800, s = 30 + rnd(i, 3) * 70;
      quadFlat(color(92, 78, 32), x - s, fl - 1.1, z - s * 0.6, x + s, fl - 1.1, z - s * 0.5, x + s * 0.8, fl - 1.1, z + s * 0.6, x - s * 0.9, fl - 1.1, z + s * 0.5);
    }
    bBegin();
    for (float z = -18; z > zb; z -= 36) {
      bQ(color(118, 98, 38), 0.8, -wx + 1, ce, z, -wx + 1, ce, z - 7, -wx + 1, fl, z - 7, -wx + 1, fl, z);
      bQ(color(118, 98, 38), 0.7, wx - 1, ce, z, wx - 1, ce, z - 7, wx - 1, fl, z - 7, wx - 1, fl, z);
    }
    bEnd();
    qX(color(64, 42, 22), 0.8, 40, 1, -wx + 0.8, fl - 14, fl, 0, zb);
    qX(color(64, 42, 22), 0.7, 40, 1, wx - 0.8, fl - 14, fl, 0, zb);
    for (float x = -wx + 200; x < wx; x += 250) ln(color(130, 124, 98), 0.9, x, ce + 0.5, 0, x, ce + 0.5, zb, 1);
    for (float z = -150; z > zb; z -= 200) ln(color(130, 124, 98), 0.9, -wx, ce + 0.5, z, wx, ce + 0.5, z, 1);
    bBegin();
    for (int a = 0; a < 4; a++) for (int k = 1; k <= 7; k++) {
      float x = (a < 2) ? (a == 0 ? -700 : -300) : (a == 2 ? 300 : 700), z = -k * 500;
      bBox(color(148, 128, 52), x - 45, x + 45, ce, fl, z - 45, z + 45, 3);
      bBox(color(64, 42, 22), x - 46, x + 46, fl - 14, fl, z - 46, z + 46, 1);
    }
    bEnd();
    boxN(wp, -wx, -640, ce, fl, -1000 - 15, -1000 + 15, 8, 3);
    boxN(wp, 600, wx, ce, fl, -1700 - 15, -1700 + 15, 8, 3);
    boxN(wp, -wx, -120, ce, fl, -2900 - 15, -2900 + 15, 12, 3);
    boxN(wp, 120, wx, ce, fl, -2900 - 15, -2900 + 15, 12, 3);
    boxN(wp, -120, 120, ce, fl - 200, -2900 - 15, -2900 + 15, 3, 1);
    qZ(color(4, 3, 2), 1, 1, 1, -120, 120, fl - 200, fl, -2900 - 20);
    emZ(color(180, 40, 30), -70, 70, fl - 190, fl - 40, -3100);
  }
}
