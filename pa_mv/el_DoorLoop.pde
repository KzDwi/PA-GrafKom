// =====================================================================
//  el_DoorLoop.pde   [ELEMENT 3D - LATAR]
//  Cuplikan pintu: kamera maju pelan ke pintu, pintu terbuka SATU KALI,
//  lalu kamera DIAM sebentar (ruangan di baliknya ternyata sama persis).
//  Setelah itu ditutup transisi mozaik (FxMosaic) dari main.
//  Semua dihitung dari clock.beatPos -> aman pause/restart.
//
//  Pemakaian:
//    doorLoop = new ElDoorLoop();                 // setup()
//    doorLoop.show(clock, 100);                   // draw()  (100 = beat mulai cuplikan)
//
//  Waktu animasi: OPEN_START/OPEN_LEN (pintu), MOVE_LEN (kamera maju),
//  MOVE_DIST (jarak maju dalam pecahan jarak antar dinding).
// =====================================================================
class ElDoorLoop {
  final float OPEN_START = 0.30;  // pintu mulai terbuka (beat sejak mulai)
  final float OPEN_LEN   = 1.00;  // lama pintu membuka
  final float MOVE_LEN   = 1.70;  // lama kamera maju, sesudah itu DIAM
  final float MOVE_DIST  = 0.42;  // jarak maju (x jarak antar dinding)
  float openAmt = 0;              // sudut bukaan pintu (0..1)

  final float L      = 420;       // jarak antar dinding pintu
  final float HALF   = 230;       // setengah lebar lorong
  final float FLOOR  = 115;       // y lantai
  final float CEIL   = -135;      // y plafon
  final float DOOR_W = 85;        // setengah lebar bukaan pintu
  final float DOOR_T = -92;       // y atas pintu
  final int   ROOMS  = 5;         // berapa ruangan digambar ke depan

  Canvas3D cv = new Canvas3D();   // kanvas 3D terpisah
  PGraphics g;                    // dipakai semua method gambar
  color bgC = color(14, 12, 5);   // warna latar & kabut
  float camZ;                     // posisi Z kamera saat ini

  void show(BeatClock t, float startBeat) {
    float local = max(0, t.beatPos - startBeat);   // beat sejak mulai
    float mv = constrain(local / MOVE_LEN, 0, 1);
    mv = 1 - pow(1 - mv, 3);                                  // maju melambat lalu berhenti
    camZ = -mv * MOVE_DIST * L;
    float ov = constrain((local - OPEN_START) / OPEN_LEN, 0, 1);
    openAmt = ov * ov * (3 - 2 * ov);                         // buka sekali, lalu tetap terbuka
    float hold = constrain((local - MOVE_LEN) / 0.3, 0, 1);                  // fase diam
    float punch = pow(1 - t.frac, 4) * (1 - 0.7 * hold);
    float sx = sin(t.beatPos * PI * 0.5) * 5 * (1 - 0.8 * hold);              // goyang X
    float sy = -abs(sin(t.beatPos * PI)) * 3 * (1 - 0.8 * hold);              // goyang Y
    float fov = radians(68) - punch * 0.04 - constrain(local / 3.0, 0, 1) * 0.06;

    g = cv.begin();
    g.background(bgC);
    g.noLights();
    g.noStroke();
    g.hint(ENABLE_DEPTH_TEST);
    g.perspective(fov, (float) g.width / g.height, 5, 3200);
    g.camera(sx, sy, camZ,
             sx * 0.3, sy + 6, camZ - 600,
             0, 1, 0);

    for (int j = 0; j < ROOMS; j++) room(j, 0);
    // pintu: dinding ke-1..ROOMS (dinding k ada di z = -k*L)
    for (int k = 1; k <= ROOMS; k++) wallWithDoor(k, 0);

    cv.end();
  }

  // ---------- 1 ruangan: lantai, plafon, dinding samping, lampu ----------
  void room(int j, float cyc) {
    float z0 = -j * L, z1 = -(j + 1) * L;
    color fl = color(120, 100, 40), ce = color(190, 175, 110), wl = color(176, 150, 62);
    slices(fl, -HALF, FLOOR, HALF, FLOOR, z0, z1, 6);
    slices(ce, -HALF, CEIL,  HALF, CEIL,  z0, z1, 6);
    slices(wl, -HALF, CEIL, -HALF, FLOOR, z0, z1, 6);
    slices(wl,  HALF, CEIL,  HALF, FLOOR, z0, z1, 6);
    // garis wallpaper vertikal
    color st = color(120, 98, 30);
    for (int i = 0; i < 8; i++) {
      float zz = z0 - 25 - i * (L / 8.0);
      zq(fogC(st, zz), -HALF + 0.6, CEIL, -HALF + 0.6, FLOOR, zz, zz - 12);
      zq(fogC(st, zz),  HALF - 0.6, CEIL,  HALF - 0.6, FLOOR, zz, zz - 12);
    }
    // plinth gelap
    zqs(color(60, 45, 12), -HALF + 0.8, FLOOR - 14, -HALF + 0.8, FLOOR, z0, z1);
    zqs(color(60, 45, 12),  HALF - 0.8, FLOOR - 14,  HALF - 0.8, FLOOR, z0, z1);
    // lampu panel putih di plafon
    float zc = (z0 + z1) / 2;
    zq(fogC(color(255, 252, 225), zc), -55, CEIL + 0.8, 55, CEIL + 0.8, zc + 55, zc - 55);
  }

  // ---------- dinding melintang ke-k dengan bukaan pintu + daun pintu ----------
  void wallWithDoor(int k, float cyc) {
    float zk = -k * L;
    float open = (k == 1) ? openAmt : 0;       // hanya pintu pertama yang terbuka
    color wl = color(168, 142, 56);
    color c = fogC(wl, zk);
    // bagian kiri & kanan bukaan + lintel di atas
    xq(c, -HALF, CEIL, -DOOR_W, FLOOR, zk);
    xq(c,  DOOR_W, CEIL, HALF, FLOOR, zk);
    xq(c, -DOOR_W, CEIL, DOOR_W, DOOR_T, zk);
    // kusen
    color fr = fogC(color(70, 48, 18), zk);
    xq(fr, -DOOR_W - 7, DOOR_T - 7, DOOR_W + 7, DOOR_T, zk + 0.6);
    xq(fr, -DOOR_W - 7, DOOR_T, -DOOR_W, FLOOR, zk + 0.6);
    xq(fr,  DOOR_W, DOOR_T, DOOR_W + 7, FLOOR, zk + 0.6);

    // daun pintu: engsel di kiri, mengayun ke arah dalam (menjauhi kamera)
    g.pushMatrix();
    g.translate(-DOOR_W, 0, zk - 1);
    g.rotateY(open * radians(105));
    float shd = constrain(0.55 + 0.45 * (1 - open), 0, 1);   // makin terbuka makin gelap
    color leaf = fogC(color(95 * shd, 62 * shd, 24 * shd), zk);
    g.fill(leaf);
    g.beginShape(QUADS);
    g.vertex(0, DOOR_T, 0); g.vertex(DOOR_W * 2, DOOR_T, 0);
    g.vertex(DOOR_W * 2, FLOOR, 0); g.vertex(0, FLOOR, 0);
    g.endShape();
    // panel & gagang
    g.fill(fogC(color(70 * shd, 44 * shd, 16 * shd), zk));
    g.beginShape(QUADS);
    g.vertex(14, DOOR_T + 14, -0.6); g.vertex(DOOR_W * 2 - 14, DOOR_T + 14, -0.6);
    g.vertex(DOOR_W * 2 - 14, DOOR_T + 78, -0.6); g.vertex(14, DOOR_T + 78, -0.6);
    g.endShape();
    g.fill(fogC(color(225, 200, 110), zk));
    g.pushMatrix(); g.translate(DOOR_W * 2 - 16, 12, 2); g.box(7, 7, 6); g.popMatrix();
    g.popMatrix();
  }

  // ---------- helper gambar ----------

  // Bidang dari (xa,ya) ke (xb,yb) memanjang dari za ke zb,
  // dipotong `n` irisan agar kabut terlihat halus
  void slices(color c, float xa, float ya, float xb, float yb, float za, float zb, int n) {
    for (int s = 0; s < n; s++) {
      float a = lerp(za, zb, s / (float) n), b = lerp(za, zb, (s + 1) / (float) n);
      zq(fogC(c, (a + b) / 2), xa, ya, xb, yb, a, b);
    }
  }

  void zqs(color c, float xa, float ya, float xb, float yb, float za, float zb) {
    slices(c, xa, ya, xb, yb, za, zb, 3);
  }

  void zq(color c, float xa, float ya, float xb, float yb, float za, float zb) {
    g.fill(c);
    g.beginShape(QUADS);
    g.vertex(xa, ya, za); g.vertex(xb, yb, za); g.vertex(xb, yb, zb); g.vertex(xa, ya, zb);
    g.endShape();
  }

  // Bidang tegak lurus sumbu z (dinding melintang)
  void xq(color c, float xa, float ya, float xb, float yb, float z) {
    g.fill(c);
    g.beginShape(QUADS);
    g.vertex(xa, ya, z); g.vertex(xb, ya, z); g.vertex(xb, yb, z); g.vertex(xa, yb, z);
    g.endShape();
  }

  // Kabut gelap: makin jauh dari kamera makin gelap
  color fogC(color c, float z) {
    float d = constrain((camZ - z) / (L * 3.6), 0, 1);
    return lerpColor(c, bgC, pow(d, 0.8));
  }
}