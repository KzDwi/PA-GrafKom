// =====================================================================
//  el_Backrooms.pde   [ELEMENT 3D - LATAR]   berisi 2 class:
//     ElBackrooms      -> lorong Backrooms kamera BERGERAK (infinite)
//     ElBackroomStatic -> 4 ruangan kamera DIAM (di bagian bawah file)
//
//  Ruangan 3D ala Backrooms. Dirender ke kanvas terpisah (Canvas3D),
//  jadi tidak bisa nembus element 2D.
//
//  backrooms = new ElBackrooms();                 // di setup()
//  backrooms.show(clock, palette);                // di draw()
//  palette: 0 = kuning, 1 = abu-abu, 2 = ungu
// =====================================================================
class ElBackrooms {
  // ---- pengaturan ----
  final float CELL          = 500;    // panjang 1 segmen lorong
  final float HALF          = 650;    // setengah lebar ruangan
  final float FLOOR         = 150;    // y lantai
  final float CEIL          = -170;   // y plafon
  final float VIEW          = 4800;   // jarak pandang sebelum hilang ke kabut
  final float UNITS_PER_BEAT = 300;   // kecepatan maju kamera per beat

  color wall, floorC, ceilC, lamp, bg;
  float travel = 0;

  Canvas3D cv = new Canvas3D();   // kanvas 3D terpisah
  PGraphics g;                    // dipakai semua method gambar di bawah

  void show(BeatClock t, int palette) {
    setPalette(palette);
    g = cv.begin();
    travel = t.beatPos * UNITS_PER_BEAT;    // posisi kamera mengikuti lagu

    // gerakan kamera sinkron beat
    float punch = pow(1 - t.frac, 4);
    float sway  = sin(t.beatPos * PI * 0.5) * 35;
    float bob   = -abs(sin(t.beatPos * PI)) * 10;
    float roll  = sin(t.beatPos * PI * 0.25) * 0.04
                + ((t.beat % 2 == 0) ? 1 : -1) * punch * 0.03;
    float fov   = radians(65) - punch * 0.07;

    g.background(bg);
    g.noLights();
    g.hint(ENABLE_DEPTH_TEST);
    g.perspective(fov, (float) g.width / g.height, 10, VIEW + 400);
    g.camera(sway, bob, 0,
           sway * 0.6, bob + 25, -1000,
           sin(roll), cos(roll), 0);

    g.pushMatrix();
    g.translate(0, 0, travel);
    g.noStroke();
    int k0 = (int) floor(travel / CELL) - 1;
    int n  = (int) ceil(VIEW / CELL) + 2;
    for (int k = k0; k < k0 + n; k++) cell(k);
    g.popMatrix();

    cv.end();   // tempel hasil 3D ke layar (di belakang element 2D)
  }

  // ---------- isi 1 segmen ----------
  void cell(int k) {
    float z0 = -k * CELL;
    float z1 = z0 - CELL;
    float zc = z0 - CELL * 0.5;

    quad3(floorC, (k % 2 == 0) ? 1.0 : 0.93,
          -HALF, FLOOR, z0,  HALF, FLOOR, z0,  HALF, FLOOR, z1,  -HALF, FLOOR, z1);
    quad3(ceilC, 1.0,
          -HALF, CEIL, z0,  HALF, CEIL, z0,  HALF, CEIL, z1,  -HALF, CEIL, z1);

    // garis kotak plafon
    g.strokeWeight(2);
    color grid = shade(ceilC, 0.6);
    for (float x = -HALF; x <= HALF; x += 130) {
      g.stroke(fog(grid, z0));
      g.line(x, CEIL + 0.5, z0, x, CEIL + 0.5, z1);
    }
    for (int j = 0; j < 4; j++) {
      float zz = z0 - j * 125;
      g.stroke(fog(grid, zz));
      g.line(-HALF, CEIL + 0.5, zz, HALF, CEIL + 0.5, zz);
    }
    g.noStroke();

    // lampu panel
    float lx = (k % 2 == 0) ? -230 : 230;
    lampPanel(lx, zc + 110, 80);
    lampPanel(-lx, zc - 110, 80);

    // dinding luar
    quad3(wall, 0.75, -HALF, CEIL, z0, -HALF, CEIL, z1, -HALF, FLOOR, z1, -HALF, FLOOR, z0);
    quad3(wall, 0.60,  HALF, CEIL, z0,  HALF, CEIL, z1,  HALF, FLOOR, z1,  HALF, FLOOR, z0);
    stripesZ(-HALF + 1.5, z0, z1);
    stripesZ( HALF - 1.5, z0, z1);

    // partisi acak (selalu sama untuk segmen yang sama)
    float h = hash(k, 1);
    if (h < 0.30) {
      block(-290, -260, z0 - 40, z0 - 440);
      stripesZ(-260 + 1.5, z0 - 40, z0 - 440);
    } else if (h < 0.60) {
      block(260, 290, z0 - 40, z0 - 440);
      stripesZ(260 - 1.5, z0 - 40, z0 - 440);
    } else if (h < 0.72) {
      block(-HALF, 140, zc + 15, zc - 15);
      stripesX(zc + 16.5, -HALF, 140);
    } else if (h < 0.84) {
      block(-140, HALF, zc + 15, zc - 15);
      stripesX(zc + 16.5, -140, HALF);
    }

    // debu melayang
    g.strokeWeight(3);
    for (int i = 0; i < 6; i++) {
      float x = (hash(k, 10 + i * 3) - 0.5) * HALF * 1.8;
      float y = lerp(CEIL, FLOOR, hash(k, 11 + i * 3)) + sin(travel * 0.01 + i * 1.7 + k) * 15;
      float z = z0 - hash(k, 12 + i * 3) * CELL;
      g.stroke(fog(color(255, 255, 210), z));
      g.point(x, y, z);
    }
    g.noStroke();
  }

  // ---------- pembantu ----------
  void lampPanel(float cx, float cz, float s) {
    float y = CEIL + 1.5;
    quad3(lamp, 1.0, cx - s, y, cz - s,  cx + s, y, cz - s,  cx + s, y, cz + s,  cx - s, y, cz + s);
  }

  void block(float x0, float x1, float z0, float z1) {
    float y0 = CEIL, y1 = FLOOR;
    quad3(wall, 1.00, x0, y0, z0,  x1, y0, z0,  x1, y1, z0,  x0, y1, z0);
    quad3(wall, 0.70, x0, y0, z1,  x1, y0, z1,  x1, y1, z1,  x0, y1, z1);
    quad3(wall, 0.85, x0, y0, z0,  x0, y0, z1,  x0, y1, z1,  x0, y1, z0);
    quad3(wall, 0.60, x1, y0, z0,  x1, y0, z1,  x1, y1, z1,  x1, y1, z0);
  }

  void quad3(color c, float s,
             float x1, float y1, float z1, float x2, float y2, float z2,
             float x3, float y3, float z3, float x4, float y4, float z4) {
    color b = shade(c, s);
    g.beginShape(QUADS);
    g.fill(fog(b, z1)); g.vertex(x1, y1, z1);
    g.fill(fog(b, z2)); g.vertex(x2, y2, z2);
    g.fill(fog(b, z3)); g.vertex(x3, y3, z3);
    g.fill(fog(b, z4)); g.vertex(x4, y4, z4);
    g.endShape();
  }

  void stripesZ(float x, float za, float zb) {
    g.strokeWeight(2);
    color c = shade(wall, 0.78);
    for (float z = za - 10; z > zb; z -= 40) {
      g.stroke(fog(c, z));
      g.line(x, CEIL, z, x, FLOOR, z);
    }
    g.noStroke();
  }

  void stripesX(float z, float xa, float xb) {
    g.strokeWeight(2);
    g.stroke(fog(shade(wall, 0.78), z));
    for (float x = xa + 10; x < xb; x += 40) g.line(x, CEIL, z, x, FLOOR, z);
    g.noStroke();
  }

  color shade(color c, float s) {
    return color(red(c) * s, green(c) * s, blue(c) * s);
  }

  color fog(color c, float zWorld) {
    float d = -(zWorld + travel);
    float f = constrain((d - 200) / (VIEW - 200), 0, 1);
    return lerpColor(c, bg, f * f);
  }

  float hash(int k, int s) {
    int h = k * 374761393 + s * 668265263;
    h = (h ^ (h >>> 13)) * 1274126177;
    h = h ^ (h >>> 16);
    return (h & 0xFFFF) / 65536.0f;
  }

  void setPalette(int p) {
    switch (p) {
      case 1:  // abu-abu
        wall = color(150, 155, 162); floorC = color(85, 90, 96);
        ceilC = color(125, 130, 136); lamp = color(240, 250, 255); bg = color(14, 16, 20);
        break;
      case 2:  // ungu
        wall = color(115, 95, 135); floorC = color(45, 40, 62);
        ceilC = color(75, 65, 98); lamp = color(255, 240, 255); bg = color(14, 10, 24);
        break;
      default: // kuning
        wall = color(212, 180, 72); floorC = color(155, 128, 56);
        ceilC = color(120, 104, 56); lamp = color(255, 252, 225); bg = color(34, 28, 10);
    }
  }
}


// =====================================================================
//  ElBackroomStatic   [ELEMENT 3D - LATAR]   (menggantikan ElTunnel)
//  4 ruangan Backrooms dengan kamera DIAM, sengaja gelap + vignette.
//  Dirender ke kanvas terpisah (Canvas3D).
//
//    backroomStatic = new ElBackroomStatic();          // di setup()
//    backroomStatic.show(clock, ruang);                // di draw()
//
//  ruang: 0 = Level 0 gelap  (wallpaper kuning-hijau, pilar, 1 lampu panel)
//         1 = Lobi terbengkalai (kursi mustard, karpet pink, mural hutan)
//         2 = Lorong lengkung hijau
//         3 = Ruang bermain biru (lengkung alcove, balok mainan, jendela bulat)
//
//  Pengaturan opsional (field, ubah dari main/setup):
//    backroomStatic.gelap = 0.7;   // kecerahan global, 0 = hitam ... 1 = terang
//    backroomStatic.kedip = 0;     // >0 : lampu berdenyut halus tiap beat (mis. 0.3)
// =====================================================================
class ElBackroomStatic {
  Canvas3D cv = new Canvas3D();
  PGraphics g;

  float gelap = 0.7;
  float kedip = 0;

  // arah cahaya kasar untuk shading sisi benda (datang dari sisi kamera)
  final float LX = 0.25;
  final float LZ = 0.97;

  // dimensi ruangan aktif
  float fl, ce, wx, zb;      // lantai(y), plafon(y), setengah lebar(x), dinding belakang(z)
  float amb = 0.1;           // cahaya ambient
  float pulse = 1;

  // lampu titik (dengan warna)
  int nL = 0;
  float[] lampX = new float[8], lampY = new float[8], lampZ = new float[8];
  float[] lampI = new float[8], lampRad = new float[8];
  float[] lampR = new float[8], lampG = new float[8], lampB = new float[8];

  // ------------------------------------------------------------------
  void show(BeatClock t, int ruang) {
    g = cv.begin();
    nL = 0;
    pulse = 1 + kedip * pow(1 - t.frac, 4);

    g.background(0);
    g.noLights();
    g.noStroke();
    g.perspective(radians(62), (float) g.width / g.height, 5, 4000);
    g.camera(0, 0, 0,   0, 25, -1000,   0, 1, 0);   // kamera DIAM

    int r = ((ruang % 4) + 4) % 4;
    switch (ruang) {
      case 1:  roomLevel0();   break;
      case 2:  roomLobi();   break;
      case 3:  roomArch();   break;
      case 4:  roomPlay();   break;
      default: roomLevel0DEFAULT();
    }

    vignette();
    cv.end();
  }

  // =====================================================================
  //  RUANGAN
  // =====================================================================
  
  void roomLevel0DEFAULT() {
    fl = 130; ce = -150; wx = 330; zb = -1500; amb = 0.09;
  
    addLamp(40, -130, -900, 2.0, 430, 1.0, 1.0, 1.0);
    addLamp(-20, -130, -1400, 0.8, 380, 1.0, 1.0, 1.0);
  
    color wall = color(110);
    shell(color(125), color(55), wall, color(85));
  
    // motif garis wallpaper grayscale
    color st = color(65);
    stripesZ(-wx + 1.5, 0, zb, st, 30);
    stripesZ( wx - 1.5, 0, zb, st, 30);
    stripesX(zb + 1.5, -wx, wx, st, 30);
  
    // ambang pintu gelap di dinding kiri
    quadFlat(color(3),
             -wx + 2, ce, -430,
             -wx + 2, ce, -620,
             -wx + 2, fl, -620,
             -wx + 2, fl, -430);
  
    // pilar grayscale
    color pil = color(90);
    prism(pil,  150, fl,  -480, 110, fl - ce, 110, 0);
    prism(pil, -230, fl,  -700, 100, fl - ce, 100, 0);
    prism(pil,  170, fl, -1050, 110, fl - ce, 110, 0);
  
    // lampu panel putih keabu-abuan
    panel(40, -900, 70, 70, color(235));
    panel(-20, -1400, 55, 55, color(175));
  }
  
  // ---- 0: Level 0 gelap (referensi gambar 1) ----
  void roomLevel0() {
    fl = 130; ce = -150; wx = 330; zb = -1500; amb = 0.09;
    addLamp(40, -130, -900, 2.0, 430, 1.0, 0.95, 0.70);
    addLamp(-20, -130, -1400, 0.8, 380, 1.0, 0.95, 0.70);

    color wall = color(100, 96, 42);
    shell(color(104, 80, 30), color(66, 62, 34), wall, color(84, 80, 36));

    // motif garis wallpaper
    color st = color(70, 67, 28);
    stripesZ(-wx + 1.5, 0, zb, st, 30);
    stripesZ( wx - 1.5, 0, zb, st, 30);
    stripesX(zb + 1.5, -wx, wx, st, 30);

    // ambang pintu gelap di dinding kiri
    quadFlat(color(3, 3, 2),
             -wx + 2, ce, -430,  -wx + 2, ce, -620,  -wx + 2, fl, -620,  -wx + 2, fl, -430);

    // pilar
    color pil = color(86, 83, 38);
    prism(pil,  150, fl,  -480, 110, fl - ce, 110, 0);
    prism(pil, -230, fl,  -700, 100, fl - ce, 100, 0);
    prism(pil,  170, fl, -1050, 110, fl - ce, 110, 0);

    // lampu panel
    panel(40, -900, 70, 70, color(255, 248, 200));
    panel(-20, -1400, 55, 55, color(200, 195, 150));
  }

  // ---- 1: Lobi terbengkalai (referensi gambar 2) ----
  void roomLobi() {
    fl = 140; ce = -320; wx = 600; zb = -1000; amb = 0.13;
    addLamp(0, -300, -420, 1.1, 520, 1.0, 0.85, 0.60);
    addLamp(0, -300, -800, 0.8, 520, 1.0, 0.85, 0.60);
    addLamp(0, -60, zb + 60, 1.6, 420, 1.0, 0.55, 0.20);     // cahaya mural

    shell(color(150, 138, 120), color(118, 112, 100), color(160, 154, 138), color(120, 114, 100));

    // mural hutan di dinding belakang (emisif, gradasi)
    float mz = zb + 1.5;
    color mA = color(30, 24, 12), mB = color(150, 88, 24), mC = color(215, 135, 40), mD = color(70, 46, 16);
    quadFlat4(mA, mA, mB, mB, -330, -260, mz,  330, -260, mz,  330, -100, mz, -330, -100, mz);
    quadFlat4(mB, mB, mC, mC, -330, -100, mz,  330, -100, mz,  330,  -10, mz, -330,  -10, mz);
    quadFlat4(mC, mC, mD, mD, -330,  -10, mz,  330,  -10, mz,  330,  100, mz, -330,  100, mz);

    // karpet
    color pink = color(190, 100, 112);
    quadN(pink, 1, 6, 6, -250, fl - 1, -560,  260, fl - 1, -560,  260, fl - 1, -760, -250, fl - 1, -760);
    quadN(color(215, 130, 135), 1, 4, 3, -180, fl - 2, -600,  190, fl - 2, -600,  190, fl - 2, -720, -180, fl - 2, -720);
    quadN(color(170, 90, 100), 1, 4, 3, -160, fl - 1, -850,  170, fl - 1, -850,  170, fl - 1, -940, -160, fl - 1, -940);

    // kolom
    color kol = color(172, 168, 156);
    cyl(kol, -300, -480, 42, fl, fl - ce, 14);
    cyl(kol,  300, -620, 42, fl, fl - ce, 14);
    cyl(kol, -330, -860, 42, fl, fl - ce, 14);
    cyl(kol,  330, -950, 42, fl, fl - ce, 14);

    // kursi & sofa
    color mus = color(196, 128, 36);
    sofa(mus, -215, -400, 0.55, 130, 120);                    // kursi besar kiri depan
    sofa(mus,  250, -700, -0.70, 140, 100);                   // deretan kanan
    sofa(mus,  300, -830, -0.45, 150, 100);
    sofa(color(176, 44, 62), 270, -340, -0.35, 190, 100);     // sofa merah kanan depan

    // puing berserakan
    for (int i = 0; i < 30; i++) {
      float x = lerp(-380, 380, rnd(i, 1));
      float z = lerp(-300, -900, rnd(i, 2));
      prism(color(176, 171, 158), x, fl, z, 14 + rnd(i, 3) * 40, 4 + rnd(i, 4) * 12, 14 + rnd(i, 5) * 36, rnd(i, 6) * TWO_PI);
    }

    // panel lampu plafon redup
    panel(-120, -420, 110, 55, color(150, 132, 92));
    panel( 140, -820, 110, 55, color(150, 132, 92));
  }

  // ---- 2: Lorong lengkung hijau (referensi gambar 3) ----
  void roomArch() {
    fl = 130; ce = -270; wx = 450; zb = -2400; amb = 0.11;
    addLamp(300, -100, -300, 1.7, 520, 0.80, 1.0, 0.85);
    addLamp(-320, -100, -1000, 1.0, 620, 0.80, 1.0, 0.85);
    addLamp(200, -100, -1700, 0.7, 700, 0.80, 1.0, 0.85);

    shell(color(52, 112, 70), color(40, 84, 54), color(72, 134, 84), color(8, 20, 10));

    color fr = color(104, 168, 112), rv = color(62, 118, 74);
    for (int i = 0; i < 5; i++) {
      archWall(fr, rv, -350 - i * 450, 80, -wx, wx, ce, fl, 0, 170, -70, 14);
    }
  }

  // ---- 3: Ruang bermain biru (referensi gambar 4) ----
  void roomPlay() {
    fl = 170; ce = -230; wx = 520; zb = -420; amb = 0.20;
    addLamp(0, -200, -180, 1.5, 700, 1.0, 0.95, 0.90);
    addLamp(0, -60, zb - 40, 0.8, 260, 0.70, 0.90, 1.0);     // isi alcove

    shell(color(26, 54, 92), color(34, 80, 100), color(52, 128, 148), color(52, 128, 148), false);

    // karpet lantai: pink + setengah lingkaran kuning + cincin merah
    quadN(color(196, 100, 140), 1, 8, 8, -420, fl - 1, -100,  420, fl - 1, -100,  420, fl - 1, zb, -420, fl - 1, zb);
    ring(color(200, 50, 40), 1, 0, fl - 2.5, -250, 150, 185, 28, 1);
    disc(color(228, 190, 40), 1, 0, fl - 2.5, -250, 150, 28, 1);

    // dinding belakang dengan alcove lengkung
    float a = 120, ys = -20;
    archWall(color(58, 138, 158), color(72, 158, 176), zb, 110, -wx, wx, ce, fl, 0, a, ys, 16);
    // bidang belakang alcove (gelap) + dasar
    quadN(color(22, 56, 78), 1, 4, 4, -a, ce, zb - 110,  a, ce, zb - 110,  a, fl, zb - 110, -a, fl, zb - 110);
    quadN(color(60, 130, 150), 1, 3, 3, -a, fl - 0.5, zb,  a, fl - 0.5, zb,  a, fl - 0.5, zb - 110, -a, fl - 0.5, zb - 110);

    // bingkai empuk di sekeliling lengkung
    color rim = color(84, 168, 184);
    float zr = zb + 6, bw = 40;
    quadN(rim, 1, 2, 3, -a - bw, ys, zr, -a, ys, zr, -a, fl, zr, -a - bw, fl, zr);
    quadN(rim, 1, 2, 3,  a, ys, zr,  a + bw, ys, zr,  a + bw, fl, zr,  a, fl, zr);
    g.beginShape(QUADS);
    for (int i = 0; i < 16; i++) {
      float a0 = PI * i / 16, a1 = PI * (i + 1) / 16;
      v(rim, 1, (a) * cos(a0), ys - a * sin(a0), zr);
      v(rim, 1, (a) * cos(a1), ys - a * sin(a1), zr);
      v(rim, 1, (a + bw) * cos(a1), ys - (a + bw) * sin(a1), zr);
      v(rim, 1, (a + bw) * cos(a0), ys - (a + bw) * sin(a0), zr);
    }
    g.endShape();

    // balok mainan di dalam alcove
    float bz = zb - 65;
    prism(color(206, 150, 40),  -70, fl, bz, 70, 80, 70, 0);       // rumah-rumahan kayu
    prism(color(56, 150, 150),   10, fl, bz, 70, 28, 70, 0);
    prism(color(210, 110, 150),  10, fl - 28, bz, 70, 24, 70, 0);
    prism(color(226, 150, 40),   10, fl - 52, bz, 70, 8, 70, 0);
    prism(color(70, 140, 60),    85, fl, bz, 70, 32, 70, 0);
    prism(color(50, 110, 170),   85, fl - 32, bz, 70, 28, 70, 0);
    prism(color(190, 40, 30),    85, fl - 60, bz, 70, 24, 70, 0);

    // jendela bulat berwarna
    windowRing(-330, -105, zb + 2, 48, 32, color(228, 170, 30));
    windowRing( 340, -125, zb + 2, 48, 32, color(206, 66, 150));
  }

  // =====================================================================
  //  PEMBANTU: CAHAYA
  // =====================================================================
  void addLamp(float x, float y, float z, float inten, float rad, float r, float gr, float b) {
    lampX[nL] = x; lampY[nL] = y; lampZ[nL] = z;
    lampI[nL] = inten; lampRad[nL] = rad;
    lampR[nL] = r; lampG[nL] = gr; lampB[nL] = b;
    nL++;
  }

  // warna akhir sebuah titik setelah kena cahaya + kabut gelap
  color lit(color c, float sh, float x, float y, float z) {
    float cr = amb, cg = amb, cb = amb;
    for (int i = 0; i < nL; i++) {
      float dx = x - lampX[i], dy = y - lampY[i], dz = z - lampZ[i];
      float f = lampI[i] / (1 + (dx * dx + dy * dy + dz * dz) / (lampRad[i] * lampRad[i]));
      cr += f * lampR[i];
      cg += f * lampG[i];
      cb += f * lampB[i];
    }
    float k = sh * gelap * pulse * (1 - 0.55 * constrain((-z - 300) / 2200.0f, 0, 1));
    return color(constrain(red(c) * cr * k, 0, 255),
                 constrain(green(c) * cg * k, 0, 255),
                 constrain(blue(c) * cb * k, 0, 255));
  }

  void v(color c, float sh, float x, float y, float z) {
    g.fill(lit(c, sh, x, y, z));
    g.vertex(x, y, z);
  }

  // =====================================================================
  //  PEMBANTU: GEOMETRI
  // =====================================================================

  // titik bilinear di dalam quad P (12 angka: 4 titik x,y,z), k = 0/1/2 (x/y/z)
  float bl(float[] P, float u, float w, int k) {
    return lerp(lerp(P[k], P[3 + k], u), lerp(P[9 + k], P[6 + k], u), w);
  }

  // quad yang dipecah nu x nv supaya cahaya per-vertex terlihat halus
  void quadN(color c, float sh, int nu, int nv,
             float x1, float y1, float z1, float x2, float y2, float z2,
             float x3, float y3, float z3, float x4, float y4, float z4) {
    float[] P = { x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4 };
    g.beginShape(QUADS);
    for (int i = 0; i < nu; i++) {
      for (int j = 0; j < nv; j++) {
        float u0 = i / (float) nu, u1 = (i + 1) / (float) nu;
        float w0 = j / (float) nv, w1 = (j + 1) / (float) nv;
        v(c, sh, bl(P, u0, w0, 0), bl(P, u0, w0, 1), bl(P, u0, w0, 2));
        v(c, sh, bl(P, u1, w0, 0), bl(P, u1, w0, 1), bl(P, u1, w0, 2));
        v(c, sh, bl(P, u1, w1, 0), bl(P, u1, w1, 1), bl(P, u1, w1, 2));
        v(c, sh, bl(P, u0, w1, 0), bl(P, u0, w1, 1), bl(P, u0, w1, 2));
      }
    }
    g.endShape();
  }

  // quad emisif (tidak kena pencahayaan), 1 warna
  void quadFlat(color c,
                float x1, float y1, float z1, float x2, float y2, float z2,
                float x3, float y3, float z3, float x4, float y4, float z4) {
    quadFlat4(c, c, c, c, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4);
  }

  // quad emisif dengan warna berbeda tiap sudut (gradasi)
  void quadFlat4(color c1, color c2, color c3, color c4,
                 float x1, float y1, float z1, float x2, float y2, float z2,
                 float x3, float y3, float z3, float x4, float y4, float z4) {
    g.beginShape(QUADS);
    g.fill(c1); g.vertex(x1, y1, z1);
    g.fill(c2); g.vertex(x2, y2, z2);
    g.fill(c3); g.vertex(x3, y3, z3);
    g.fill(c4); g.vertex(x4, y4, z4);
    g.endShape();
  }

  // cangkang ruangan: lantai, plafon, dinding kiri/kanan/belakang
  void shell(color floorC, color ceilC, color wallC, color backC) {
    shell(floorC, ceilC, wallC, backC, true);
  }

  // back = false -> dinding belakang tidak digambar (dipakai ruang 3 yang punya alcove)
  void shell(color floorC, color ceilC, color wallC, color backC, boolean back) {
    quadN(floorC, 1.0, 14, 14, -wx, fl, 0,  wx, fl, 0,  wx, fl, zb, -wx, fl, zb);
    quadN(ceilC,  0.9, 8, 10,  -wx, ce, 0,  wx, ce, 0,  wx, ce, zb, -wx, ce, zb);
    quadN(wallC,  0.8, 14, 4,  -wx, ce, 0, -wx, ce, zb, -wx, fl, zb, -wx, fl, 0);
    quadN(wallC,  0.7, 14, 4,   wx, ce, 0,  wx, ce, zb,  wx, fl, zb,  wx, fl, 0);
    if (back) quadN(backC,  0.9, 8, 4,   -wx, ce, zb,  wx, ce, zb,  wx, fl, zb, -wx, fl, zb);
  }

  // panel lampu plafon (emisif)
  void panel(float cx, float cz, float hw, float hd, color c) {
    float y = ce + 1.5;
    quadFlat(c, cx - hw, y, cz - hd, cx + hw, y, cz - hd, cx + hw, y, cz + hd, cx - hw, y, cz + hd);
  }

  // garis vertikal motif wallpaper di dinding samping (x tetap, sepanjang z)
  void stripesZ(float x, float za, float zb2, color c, float step) {
    g.strokeWeight(2);
    for (float z = za - 10; z > zb2; z -= step) {
      g.stroke(lit(c, 0.8, x, (ce + fl) / 2, z));
      g.line(x, ce, z, x, fl, z);
    }
    g.noStroke();
  }

  // garis vertikal motif wallpaper di dinding belakang (z tetap, sepanjang x)
  void stripesX(float z, float xa, float xb, color c, float step) {
    g.strokeWeight(2);
    for (float x = xa + 10; x < xb; x += step) {
      g.stroke(lit(c, 0.8, x, (ce + fl) / 2, z));
      g.line(x, ce, z, x, fl, z);
    }
    g.noStroke();
  }

  // balok (boleh diputar yaw). yb = y alas, h = tinggi
  void prism(color c, float cx, float yb, float cz, float w, float h, float d, float yaw) {
    float[] px = new float[4], pz = new float[4];
    float[] ox = { -w / 2, w / 2, w / 2, -w / 2 };
    float[] oz = { -d / 2, -d / 2, d / 2, d / 2 };
    float cs = cos(yaw), sn = sin(yaw);
    for (int i = 0; i < 4; i++) {
      px[i] = cx + ox[i] * cs - oz[i] * sn;
      pz[i] = cz + ox[i] * sn + oz[i] * cs;
    }
    float yt = yb - h;
    for (int i = 0; i < 4; i++) {
      int j = (i + 1) % 4;
      float ex = px[j] - px[i], ez = pz[j] - pz[i];
      float len = sqrt(ex * ex + ez * ez);
      float nx = ez / len, nz = -ex / len;
      float mx = (px[i] + px[j]) / 2 - cx, mz = (pz[i] + pz[j]) / 2 - cz;
      if (nx * mx + nz * mz < 0) { nx = -nx; nz = -nz; }
      float sh = 0.5 + 0.5 * max(0, nx * LX + nz * LZ);
      quadN(c, sh, 2, 2, px[i], yb, pz[i], px[j], yb, pz[j], px[j], yt, pz[j], px[i], yt, pz[i]);
    }
    quadN(c, 1.0, 2, 2, px[0], yt, pz[0], px[1], yt, pz[1], px[2], yt, pz[2], px[3], yt, pz[3]);
  }

  // silinder (kolom) tanpa tutup
  void cyl(color c, float cx, float cz, float r, float yb, float h, int seg) {
    float yt = yb - h;
    for (int i = 0; i < seg; i++) {
      float a0 = TWO_PI * i / seg, a1 = TWO_PI * (i + 1) / seg, am = (a0 + a1) / 2;
      float sh = 0.45 + 0.55 * max(0, cos(am) * LX + sin(am) * LZ);
      quadN(c, sh, 1, 3,
            cx + r * cos(a0), yb, cz + r * sin(a0),
            cx + r * cos(a1), yb, cz + r * sin(a1),
            cx + r * cos(a1), yt, cz + r * sin(a1),
            cx + r * cos(a0), yt, cz + r * sin(a0));
    }
  }

  // cincin. plane 0 = tegak (bidang XY), plane 1 = rata (bidang XZ / lantai)
  void ring(color c, float sh, float cx, float cy, float cz, float r0, float r1, int seg, int plane) {
    g.beginShape(QUADS);
    for (int i = 0; i < seg; i++) {
      float a0 = TWO_PI * i / seg, a1 = TWO_PI * (i + 1) / seg;
      ringV(c, sh, cx, cy, cz, r0, a0, plane);
      ringV(c, sh, cx, cy, cz, r0, a1, plane);
      ringV(c, sh, cx, cy, cz, r1, a1, plane);
      ringV(c, sh, cx, cy, cz, r1, a0, plane);
    }
    g.endShape();
  }

  void ringV(color c, float sh, float cx, float cy, float cz, float r, float a, int plane) {
    if (plane == 0) v(c, sh, cx + r * cos(a), cy + r * sin(a), cz);
    else            v(c, sh, cx + r * cos(a), cy, cz + r * sin(a));
  }

  // piringan penuh (dipecah 3 cincin supaya cahaya halus)
  void disc(color c, float sh, float cx, float cy, float cz, float r, int seg, int plane) {
    for (int k = 0; k < 3; k++) ring(c, sh, cx, cy, cz, r * k / 3.0f, r * (k + 1) / 3.0f, seg, plane);
  }

  // jendela bulat berbingkai warna
  void windowRing(float cx, float cy, float z, float ro, float ri, color c) {
    ring(c, 1, cx, cy, z + 1, ri, ro, 24, 0);
    disc(color(36, 70, 90), 1, cx, cy, z, ri, 24, 0);
    disc(color(200, 90, 40), 1, cx - ri * 0.3, cy + ri * 0.1, z + 0.5, ri * 0.3, 10, 0);
    disc(color(60, 140, 200), 1, cx + ri * 0.25, cy - ri * 0.2, z + 0.5, ri * 0.28, 10, 0);
  }

  // dinding berlubang lengkung (arch). zF = muka depan, th = tebal
  void archWall(color c, color rev, float zF, float th, float xL, float xR, float yT, float yB,
                float cx, float a, float ys, int seg) {
    quadN(c, 1.0, 3, 3, xL, yT, zF, cx - a, yT, zF, cx - a, yB, zF, xL, yB, zF);
    quadN(c, 1.0, 3, 3, cx + a, yT, zF, xR, yT, zF, xR, yB, zF, cx + a, yB, zF);

    // bagian di atas lengkung
    g.beginShape(QUADS);
    for (int i = 0; i < seg; i++) {
      float a0 = PI * i / seg, a1 = PI * (i + 1) / seg;
      float x0 = cx + a * cos(a0), y0 = ys - a * sin(a0);
      float x1 = cx + a * cos(a1), y1 = ys - a * sin(a1);
      v(c, 1.0, x0, y0, zF);
      v(c, 1.0, x1, y1, zF);
      v(c, 1.0, x1, yT, zF);
      v(c, 1.0, x0, yT, zF);
    }
    g.endShape();

    // sisi dalam (ketebalan) lengkung
    quadN(rev, 0.75, 2, 2, cx - a, ys, zF, cx - a, ys, zF - th, cx - a, yB, zF - th, cx - a, yB, zF);
    quadN(rev, 0.60, 2, 2, cx + a, ys, zF, cx + a, ys, zF - th, cx + a, yB, zF - th, cx + a, yB, zF);
    g.beginShape(QUADS);
    for (int i = 0; i < seg; i++) {
      float a0 = PI * i / seg, a1 = PI * (i + 1) / seg;
      float x0 = cx + a * cos(a0), y0 = ys - a * sin(a0);
      float x1 = cx + a * cos(a1), y1 = ys - a * sin(a1);
      v(rev, 0.55, x0, y0, zF);
      v(rev, 0.55, x1, y1, zF);
      v(rev, 0.55, x1, y1, zF - th);
      v(rev, 0.55, x0, y0, zF - th);
    }
    g.endShape();
  }

  // sofa / kursi menghadap +z lokal, diputar yaw
  void sofa(color c, float cx, float cz, float yaw, float len, float dep) {
    part(c, cx, cz, yaw, 0, 0, len, 40, dep);                              // dudukan
    part(c, cx, cz, yaw, 0, -(dep / 2 - 14), len, 100, 28);                // sandaran
    part(c, cx, cz, yaw, -(len / 2 - 14), 0, 28, 68, dep);                 // lengan kiri
    part(c, cx, cz, yaw,  (len / 2 - 14), 0, 28, 68, dep);                 // lengan kanan
  }

  void part(color c, float cx, float cz, float yaw, float ox, float oz, float w, float h, float d) {
    float cs = cos(yaw), sn = sin(yaw);
    prism(c, cx + ox * cs - oz * sn, fl, cz + ox * sn + oz * cs, w, h, d, yaw);
  }

  // angka acak stabil 0..1
  float rnd(int i, int s) {
    int h = i * 374761393 + s * 668265263;
    h = (h ^ (h >>> 13)) * 1274126177;
    h = h ^ (h >>> 16);
    return (h & 0xFFFF) / 65536.0f;
  }

  // gelapkan tepi layar
  void vignette() {
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
      g.fill(0, 215);
      g.vertex(cx + cos(a) * rr, cy + sin(a) * rr, 0);
    }
    g.endShape();
    g.hint(ENABLE_DEPTH_TEST);
  }
}
