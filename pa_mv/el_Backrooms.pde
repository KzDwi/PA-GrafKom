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
//
//  UPDATE:
//   - ElBackrooms: pencahayaan HD per-vertex (tiap lampu panel jadi lampu
//     titik sungguhan: kolam cahaya di lantai, gradasi di dinding, pantulan
//     glossy di lantai, AO di sudut, glow lampu, lampu rusak berkedip,
//     tone-mapping, vignette) + detail: plint, wainscot, crown, sambungan karpet.
//   - ElBackroomStatic: tiap ruangan ditambah banyak detail (trim, grid
//     plafon, ubin lantai, bayangan sudut, glow lampu, debu, dekorasi, dll).
// =====================================================================
class ElBackrooms {
  // ---- pengaturan ----
  final float CELL          = 500;    // panjang 1 segmen lorong
  final float HALF          = 650;    // setengah lebar ruangan
  final float FLOOR         = 150;    // y lantai
  final float CEIL          = -170;   // y plafon
  final float VIEW          = 4800;   // jarak pandang sebelum hilang ke kabut
  final float UNITS_PER_BEAT = 300;   // kecepatan maju kamera per beat

  // ---- pengaturan pencahayaan ----
  final float LAMP_I    = 1.7;   // kekuatan tiap lampu
  final float LAMP_R    = 420;   // radius jatuh cahaya lampu
  final float LAMP_DROP = 20;    // lampu "menggantung" sekian unit di bawah plafon
  final float AMB       = 0.30;  // cahaya ambient
  final float VIG       = 150;   // kekuatan vignette (0 = mati, 255 = pekat)

  color wall, floorC, ceilC, lamp, bg;
  float travel = 0;

  // keadaan frame saat ini
  float camX = 0, camY = 0, camZ = 0;   // posisi kamera (koordinat lokal geometri)
  float beatT = 0;
  float lampPunch = 1;
  float lr = 1, lg = 1, lb = 1;         // warna lampu 0..1
  int   curK = 0;                       // segmen yang sedang digambar
  float gloss = 0;                      // >0 : permukaan mengkilap (lantai)

  Canvas3D cv = new Canvas3D();   // kanvas 3D terpisah
  PGraphics g;                    // dipakai semua method gambar di bawah

  void show(BeatClock t, int palette) {
    setPalette(palette);
    lr = red(lamp) / 255.0f; lg = green(lamp) / 255.0f; lb = blue(lamp) / 255.0f;

    g = cv.begin();
    beatT  = t.beatPos;
    travel = t.beatPos * UNITS_PER_BEAT;    // posisi kamera mengikuti lagu

    // gerakan kamera sinkron beat
    float punch = pow(1 - t.frac, 4);
    float sway  = sin(t.beatPos * PI * 0.5) * 35;
    float bob   = -abs(sin(t.beatPos * PI)) * 10;
    float roll  = sin(t.beatPos * PI * 0.25) * 0.04
                + ((t.beat % 2 == 0) ? 1 : -1) * punch * 0.03;
    float fov   = radians(65) - punch * 0.07;
    lampPunch = 1 + punch * 0.10;

    camX = sway; camY = bob; camZ = -travel;

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

    // pass kedua: glow lampu (additive, digambar setelah semua benda solid)
    g.hint(DISABLE_DEPTH_MASK);
    g.blendMode(ADD);
    for (int k = k0; k < k0 + n; k++) halo(k);
    g.blendMode(BLEND);
    g.hint(ENABLE_DEPTH_MASK);
    g.popMatrix();

    vignette();
    cv.end();   // tempel hasil 3D ke layar (di belakang element 2D)
  }

  // ---------- isi 1 segmen ----------
  void cell(int k) {
    curK = k;
    float z0 = -k * CELL;
    float z1 = z0 - CELL;
    float zc = z0 - CELL * 0.5;

    // ---- lantai (glossy, kena pantulan lampu) ----
    gloss = 0.55;
    quadL(floorC, (k % 2 == 0) ? 1.0 : 0.94, 0, -1, 0, 8, 4,
          -HALF, FLOOR, z0,  HALF, FLOOR, z0,  HALF, FLOOR, z1,  -HALF, FLOOR, z1);
    gloss = 0;

    // sambungan karpet
    color seam = shade(floorC, 0.72);
    for (int j = 0; j < 4; j++)
      lineL(seam, 1, 1.5, 0, -1, 0, -HALF, FLOOR - 0.5, z0 - j * 125, HALF, FLOOR - 0.5, z0 - j * 125, 3);
    for (float x = -HALF + 130; x < HALF - 1; x += 260)
      lineL(seam, 1, 1.5, 0, -1, 0, x, FLOOR - 0.5, z0, x, FLOOR - 0.5, z1, 2);

    // ---- plafon ----
    quadL(ceilC, 1.0, 0, 1, 0, 6, 3,
          -HALF, CEIL, z0,  HALF, CEIL, z0,  HALF, CEIL, z1,  -HALF, CEIL, z1);

    // garis kotak plafon
    color grid = shade(ceilC, 0.6);
    for (float x = -HALF; x <= HALF; x += 130)
      lineL(grid, 1, 2, 0, 1, 0, x, CEIL + 0.5, z0, x, CEIL + 0.5, z1, 2);
    for (int j = 0; j < 4; j++) {
      float zz = z0 - j * 125;
      lineL(grid, 1, 2, 0, 1, 0, -HALF, CEIL + 0.5, zz, HALF, CEIL + 0.5, zz, 3);
    }

    // lampu panel
    float lx = lampX(k, 0);
    lampPanel(lx,  zc + 110, 80, lampGain(k, 0));
    lampPanel(-lx, zc - 110, 80, lampGain(k, 1));

    // ---- dinding luar ----
    quadL(wall, 0.75,  1, 0, 0, 3, 2, -HALF, CEIL, z0, -HALF, CEIL, z1, -HALF, FLOOR, z1, -HALF, FLOOR, z0);
    quadL(wall, 0.60, -1, 0, 0, 3, 2,  HALF, CEIL, z0,  HALF, CEIL, z1,  HALF, FLOOR, z1,  HALF, FLOOR, z0);
    stripesZ(-HALF + 1.5, z0, z1,  1);
    stripesZ( HALF - 1.5, z0, z1, -1);
    wallTrim(-HALF, z0, z1,  1);
    wallTrim( HALF, z0, z1, -1);

    // ---- partisi acak (selalu sama untuk segmen yang sama) ----
    float h = hash(k, 1);
    if (h < 0.30) {
      block(-290, -260, z0 - 40, z0 - 440);
      stripesZ(-260 + 1.5, z0 - 40, z0 - 440, 1);
    } else if (h < 0.60) {
      block(260, 290, z0 - 40, z0 - 440);
      stripesZ(260 - 1.5, z0 - 40, z0 - 440, -1);
    } else if (h < 0.72) {
      block(-HALF, 140, zc + 15, zc - 15);
      stripesX(zc + 16.5, -HALF, 140);
    } else if (h < 0.84) {
      block(-140, HALF, zc + 15, zc - 15);
      stripesX(zc + 16.5, -140, HALF);
    }

    // ---- debu melayang (lebih terang kalau dekat lampu) ----
    g.strokeWeight(3);
    for (int i = 0; i < 6; i++) {
      float x = (hash(k, 10 + i * 3) - 0.5) * HALF * 1.8;
      float y = lerp(CEIL, FLOOR, hash(k, 11 + i * 3)) + sin(travel * 0.01 + i * 1.7 + k) * 15;
      float z = z0 - hash(k, 12 + i * 3) * CELL;
      g.stroke(lit(color(255, 255, 215), 1.6, x, y, z, 0, 1, 0));
      g.point(x, y, z);
    }
    g.noStroke();
  }

  // ---------- LAMPU ----------
  float lampX(int k, int i) {
    float lx = (k % 2 == 0) ? -230 : 230;
    return (i == 0) ? lx : -lx;
  }

  float lampZ(int k, int i) {
    float zc = -k * CELL - CELL * 0.5;
    return (i == 0) ? zc + 110 : zc - 110;
  }

  // sebagian lampu rusak dan berkedip
  float lampGain(int k, int i) {
    float h = hash(k, 40 + i);
    if (h < 0.15) {
      float n = sin(beatT * 19.0 + h * 90) * sin(beatT * 5.3 + h * 40);
      return (n > 0.5) ? 0.2 : 1.0;
    }
    return 1.0;
  }

  void lampPanel(float cx, float cz, float s, float gain) {
    float y = CEIL + 1.0;
    quad3(shade(ceilC, 0.55), 1.0,
          cx - s - 8, y, cz - s - 8,  cx + s + 8, y, cz - s - 8,
          cx + s + 8, y, cz + s + 8,  cx - s - 8, y, cz + s + 8);
    y = CEIL + 1.5;
    float e = constrain(gain * lampPunch, 0, 1.3);
    quad3(shade(lamp, e), 1.0,
          cx - s, y, cz - s,  cx + s, y, cz - s,  cx + s, y, cz + s,  cx - s, y, cz + s);
    // pembagi diffuser
    g.strokeWeight(2);
    g.stroke(fog(shade(lamp, 0.55 * e), cz));
    g.line(cx, y + 0.3, cz - s, cx, y + 0.3, cz + s);
    g.line(cx - s, y + 0.3, cz, cx + s, y + 0.3, cz);
    g.noStroke();
  }

  // glow lembut di sekitar lampu (additive)
  void halo(int k) {
    for (int i = 0; i < 2; i++) {
      float cx = lampX(k, i), cz = lampZ(k, i);
      float f  = constrain((-(cz + travel) - 200) / (VIEW - 200), 0, 1);
      float a  = 85 * lampGain(k, i) * (1 - f * f) * lampPunch;
      if (a < 1) continue;
      float y = CEIL + 0.8;
      g.beginShape(TRIANGLE_FAN);
      g.fill(red(lamp), green(lamp), blue(lamp), a);
      g.vertex(cx, y, cz);
      for (int j = 0; j <= 16; j++) {
        float an = TWO_PI * j / 16;
        g.fill(red(lamp), green(lamp), blue(lamp), 0);
        g.vertex(cx + cos(an) * 300, y, cz + sin(an) * 300);
      }
      g.endShape();
    }
  }

  // ---------- PENCAHAYAAN ----------
  // warna akhir titik: ambient + 6 lampu terdekat (diffuse + spekular) + AO + tone-map + kabut
  color lit(color c, float s, float x, float y, float z, float nx, float ny, float nz) {
    float mr = AMB * lr, mg = AMB * lg, mb = AMB * lb;
    float sp = 0;
    for (int kk = curK - 1; kk <= curK + 1; kk++) {
      for (int i = 0; i < 2; i++) {
        float dx = lampX(kk, i) - x;
        float dy = CEIL + LAMP_DROP - y;
        float dz = lampZ(kk, i) - z;
        float d2 = dx * dx + dy * dy + dz * dz;
        float d  = sqrt(d2) + 0.001;
        float gain = lampGain(kk, i);
        float att  = LAMP_I * gain / (1 + d2 / (LAMP_R * LAMP_R));
        float ndl  = (nx * dx + ny * dy + nz * dz) / d;
        float diff = constrain((ndl + 0.35) / 1.35, 0, 1);   // wrap lighting (lembut)
        float w = att * diff;
        mr += w * lr; mg += w * lg; mb += w * lb;

        if (gloss > 0) {   // pantulan lampu di lantai (Blinn-Phong)
          float vx = camX - x, vy = camY - y, vz = camZ - z;
          float vl = sqrt(vx * vx + vy * vy + vz * vz) + 0.001;
          float hx = dx / d + vx / vl, hy = dy / d + vy / vl, hz = dz / d + vz / vl;
          float hl = sqrt(hx * hx + hy * hy + hz * hz) + 0.001;
          float nh = (nx * hx + ny * hy + nz * hz) / hl;
          if (nh > 0) sp += pow(nh, 48) * gloss * att;
        }
      }
    }

    // ambient occlusion palsu di sudut dinding / lantai / plafon
    float ao = 1;
    if (abs(nx) < 0.5) {
      float ex = constrain((abs(x) - (HALF - 140)) / 140.0f, 0, 1);
      ao -= 0.28 * ex * ex;
    }
    if (abs(ny) < 0.5) {
      float e1 = constrain((y - (FLOOR - 70)) / 70.0f, 0, 1);
      float e2 = constrain(((CEIL + 70) - y) / 70.0f, 0, 1);
      ao -= 0.30 * e1 * e1 + 0.22 * e2 * e2;
    }
    float k = s * max(ao, 0.2);

    float R = red(c)   * k * mr + sp * lr * 255;
    float G = green(c) * k * mg + sp * lg * 255;
    float B = blue(c)  * k * mb + sp * lb * 255;
    return fog(color(tm(R), tm(G), tm(B)), z);
  }

  // tone-mapping lembut: terang tidak langsung "jebol" jadi putih rata
  float tm(float v) {
    if (v < 140) return max(v, 0);
    return 140 + 115 * (1 - exp(-(v - 140) / 115.0f));
  }

  void vL(color c, float s, float nx, float ny, float nz, float x, float y, float z) {
    g.fill(lit(c, s, x, y, z, nx, ny, nz));
    g.vertex(x, y, z);
  }

  // titik bilinear di dalam quad P (12 angka), k = 0/1/2 (x/y/z)
  float bl(float[] P, float u, float w, int k) {
    return lerp(lerp(P[k], P[3 + k], u), lerp(P[9 + k], P[6 + k], u), w);
  }

  // quad dengan pencahayaan per-vertex, dipecah nu x nv
  void quadL(color c, float s, float nx, float ny, float nz, int nu, int nv,
             float x1, float y1, float z1, float x2, float y2, float z2,
             float x3, float y3, float z3, float x4, float y4, float z4) {
    float[] P = { x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4 };
    g.beginShape(QUADS);
    for (int i = 0; i < nu; i++) {
      for (int j = 0; j < nv; j++) {
        float u0 = i / (float) nu, u1 = (i + 1) / (float) nu;
        float w0 = j / (float) nv, w1 = (j + 1) / (float) nv;
        vL(c, s, nx, ny, nz, bl(P, u0, w0, 0), bl(P, u0, w0, 1), bl(P, u0, w0, 2));
        vL(c, s, nx, ny, nz, bl(P, u1, w0, 0), bl(P, u1, w0, 1), bl(P, u1, w0, 2));
        vL(c, s, nx, ny, nz, bl(P, u1, w1, 0), bl(P, u1, w1, 1), bl(P, u1, w1, 2));
        vL(c, s, nx, ny, nz, bl(P, u0, w1, 0), bl(P, u0, w1, 1), bl(P, u0, w1, 2));
      }
    }
    g.endShape();
  }

  // garis dengan warna per-vertex (disegmentasi supaya cahaya terlihat di sepanjang garis)
  void lineL(color c, float s, float wgt, float nx, float ny, float nz,
             float x1, float y1, float z1, float x2, float y2, float z2, int seg) {
    g.strokeWeight(wgt);
    g.beginShape(LINES);
    for (int i = 0; i < seg; i++) {
      float t0 = i / (float) seg, t1 = (i + 1) / (float) seg;
      float ax = lerp(x1, x2, t0), ay = lerp(y1, y2, t0), az = lerp(z1, z2, t0);
      float bx = lerp(x1, x2, t1), by = lerp(y1, y2, t1), bz = lerp(z1, z2, t1);
      g.stroke(lit(c, s, ax, ay, az, nx, ny, nz)); g.vertex(ax, ay, az);
      g.stroke(lit(c, s, bx, by, bz, nx, ny, nz)); g.vertex(bx, by, bz);
    }
    g.endShape();
    g.noStroke();
  }

  // ---------- pembantu geometri ----------
  void block(float x0, float x1, float z0, float z1) {
    float y0 = CEIL, y1 = FLOOR;
    int nx = max(1, (int) (abs(x1 - x0) / 100));
    int nz = max(1, (int) (abs(z1 - z0) / 100));
    quadL(wall, 1.00,  0, 0,  1, nx, 2, x0, y0, z0,  x1, y0, z0,  x1, y1, z0,  x0, y1, z0);
    quadL(wall, 0.70,  0, 0, -1, nx, 2, x0, y0, z1,  x1, y0, z1,  x1, y1, z1,  x0, y1, z1);
    quadL(wall, 0.85, -1, 0,  0, nz, 2, x0, y0, z0,  x0, y0, z1,  x0, y1, z1,  x0, y1, z0);
    quadL(wall, 0.60,  1, 0,  0, nz, 2, x1, y0, z0,  x1, y0, z1,  x1, y1, z1,  x1, y1, z0);
  }

  // plint, wainscot, rel dinding, dan list atas
  void wallTrim(float x, float za, float zb, float nx) {
    float o = x + nx * 0.8;
    color dark = shade(wall, 0.68);
    quadL(dark, 0.8, nx, 0, 0, 2, 1, o, FLOOR - 70, za, o, FLOOR - 70, zb, o, FLOOR, zb, o, FLOOR, za);
    float o2 = x + nx * 1.4;
    quadL(shade(wall, 0.38), 0.8, nx, 0, 0, 2, 1, o2, FLOOR - 18, za, o2, FLOOR - 18, zb, o2, FLOOR, zb, o2, FLOOR, za);   // plint
    quadL(shade(ceilC, 0.75), 0.8, nx, 0, 0, 2, 1, o2, CEIL, za, o2, CEIL, zb, o2, CEIL + 14, zb, o2, CEIL + 14, za);       // crown
    lineL(shade(wall, 1.15), 1, 2, nx, 0, 0, o, FLOOR - 70, za, o, FLOOR - 70, zb, 2);                                       // rel
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

  void stripesZ(float x, float za, float zb, float nx) {
    color c = shade(wall, 0.78);
    for (float z = za - 10; z > zb; z -= 40)
      lineL(c, 1, 2, nx, 0, 0, x, CEIL + 14, z, x, FLOOR - 72, z, 1);
  }

  void stripesX(float z, float xa, float xb) {
    color c = shade(wall, 0.78);
    for (float x = xa + 10; x < xb; x += 40)
      lineL(c, 1, 2, 0, 0, 1, x, CEIL + 14, z, x, FLOOR - 72, z, 1);
  }

  color shade(color c, float s) {
    return color(constrain(red(c) * s, 0, 255), constrain(green(c) * s, 0, 255), constrain(blue(c) * s, 0, 255));
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
      g.fill(0, VIG);
      g.vertex(cx + cos(a) * rr, cy + sin(a) * rr, 0);
    }
    g.endShape();
    g.hint(ENABLE_DEPTH_TEST);
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
//    backroomStatic.debu  = 50;    // jumlah partikel debu (0 = mati)
// =====================================================================
class ElBackroomStatic {
  Canvas3D cv = new Canvas3D();
  PGraphics g;

  float gelap = 0.7;
  float kedip = 0;
  int   debu  = 0;

  // arah cahaya kasar untuk shading sisi benda (datang dari sisi kamera)
  final float LX = 0.25;
  final float LZ = 0.97;

  // dimensi ruangan aktif
  float fl, ce, wx, zb;      // lantai(y), plafon(y), setengah lebar(x), dinding belakang(z)
  float amb = 0.1;           // cahaya ambient
  float pulse = 1;
  float tp = 0;              // posisi beat (untuk animasi debu)
  boolean backWall = true;   // ruangan punya dinding belakang polos?
  int prismSub = 2;          // pecahan sisi balok

  // lampu titik (dengan warna)
  int nL = 0;
  float[] lampX = new float[8], lampY = new float[8], lampZ = new float[8];
  float[] lampI = new float[8], lampRad = new float[8];
  float[] lampR = new float[8], lampG = new float[8], lampB = new float[8];

  // antrian glow lampu plafon (digambar paling akhir)
  int nG = 0;
  float[] gX = new float[10], gZ = new float[10], gRX = new float[10], gRZ = new float[10];
  float[] gR = new float[10], gG = new float[10], gB = new float[10];

  // ------------------------------------------------------------------
  void show(BeatClock t, int ruang) {
    g = cv.begin();
    nL = 0;
    nG = 0;
    tp = t.beatPos;
    pulse = 1 + kedip * pow(1 - t.frac, 4);

    g.background(0);
    g.noLights();
    g.noStroke();
    g.perspective(radians(62), (float) g.width / g.height, 5, 4000);
    g.camera(0, 0, 0,   0, 25, -1000,   0, 1, 0);   // kamera DIAM

    switch (ruang) {
      case 1:  roomLevel0();   break;
      case 2:  roomLobi();   break;
      case 3:  roomArch();   break;
      case 4:  roomPlay();   break;
      default: roomLevel0DEFAULT();
    }

    if (debu > 0) dust(debu);
    glows();
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

    // ---- detail tambahan ----
    level0Details(color(70), color(78), color(48), color(34));
    // pilar: alas & kepala
    prism(color(70),  150, fl, -480, 122, 14, 122, 0);
    prism(color(70), -230, fl, -700, 112, 14, 112, 0);
    prism(color(70),  170, fl, -1050, 122, 14, 122, 0);
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

    // ---- detail tambahan ----
    level0Details(color(70, 66, 30), color(62, 58, 26), color(70, 52, 20), color(58, 44, 14));
    prism(color(72, 69, 32),  150, fl, -480, 122, 14, 122, 0);
    prism(color(72, 69, 32), -230, fl, -700, 112, 14, 112, 0);
    prism(color(72, 69, 32),  170, fl, -1050, 122, 14, 122, 0);
  }

  // detail bersama untuk Level 0 (kuning & abu-abu)
  void level0Details(color trimC, color cseam, color fseam, color stainC) {
    trim(trimC);
    // ubin plafon + ventilasi
    gridH(cseam, ce + 0.6, -wx, wx, -110, zb, 120, 110, 2);
    vent(-170, -380, 42, 22);
    vent(200, -1150, 42, 22);
    // sambungan karpet
    gridH(fseam, fl - 0.5, -wx, wx, -20, zb, 110, 110, 1);
    // bingkai pintu
    prism(trimC, -wx + 7, fl, -430, 14, fl - ce, 14, 0);
    prism(trimC, -wx + 7, fl, -620, 14, fl - ce, 14, 0);
    // noda lantai
    stain(stainC, -90, -300, 38);
    stain(stainC, -70, -280, 26);
    stain(stainC, 120, -820, 62);
    stain(stainC, 150, -850, 34);
    stain(stainC, -150, -1200, 50);
    // stopkontak di dinding belakang
    prism(mul(trimC, 1.4), -200, fl - 35, zb + 3, 16, 26, 6, 0);
    prism(mul(trimC, 1.4),  220, fl - 35, zb + 3, 16, 26, 6, 0);
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

    // puing berserakan (lebih banyak)
    for (int i = 0; i < 40; i++) {
      float x = lerp(-380, 380, rnd(i, 1));
      float z = lerp(-300, -900, rnd(i, 2));
      prism(color(176, 171, 158), x, fl, z, 14 + rnd(i, 3) * 40, 4 + rnd(i, 4) * 12, 14 + rnd(i, 5) * 36, rnd(i, 6) * TWO_PI);
    }

    // panel lampu plafon redup
    panel(-120, -420, 110, 55, color(150, 132, 92));
    panel( 140, -820, 110, 55, color(150, 132, 92));

    // ---- detail tambahan ----
    trim(color(110, 102, 88));
    wainscot(color(128, 118, 100), 90);
    gridH(color(95, 90, 80), ce + 0.6, -wx, wx, -60, zb, 150, 130, 2);     // rangka plafon
    gridH(color(104, 98, 88), fl - 0.5, -wx, wx, -20, zb, 120, 120, 1);    // ubin lantai

    // alas & kepala kolom
    float[] cxk = { -300, 300, -330, 330 };
    float[] czk = { -480, -620, -860, -950 };
    for (int i = 0; i < 4; i++) {
      prism(color(150, 146, 134), cxk[i], fl, czk[i], 76, 16, 76, 0);
      prism(color(150, 146, 134), cxk[i], ce + 18, czk[i], 76, 18, 76, 0);
    }

    // panel plafon yang menggantung rusak
    for (int i = 0; i < 3; i++) {
      float x = lerp(-300, 300, rnd(i, 41)), z = -200 - i * 260;
      quadN(color(130, 124, 108), 1, 2, 2,
            x - 45, ce + 1, z - 45,  x + 45, ce + 1, z - 45,
            x + 45, ce + 55, z + 45,  x - 45, ce + 55, z + 45);
    }

    // bingkai mural
    float fz = mz + 0.6;
    color fr = color(40, 28, 14);
    quadFlat(fr, -345, -275, fz,  345, -275, fz,  345, -262, fz, -345, -262, fz);
    quadFlat(fr, -345,  100, fz,  345,  100, fz,  345,  113, fz, -345,  113, fz);
    quadFlat(fr, -345, -275, fz, -332, -275, fz, -332,  113, fz, -345,  113, fz);
    quadFlat(fr,  332, -275, fz,  345, -275, fz,  345,  113, fz,  332,  113, fz);

    // garis tepi karpet
    color bd = color(235, 160, 165);
    lineL(bd, 1, 2, -250, fl - 2.6, -560,  260, fl - 2.6, -560, 2);
    lineL(bd, 1, 2, -250, fl - 2.6, -760,  260, fl - 2.6, -760, 2);
    lineL(bd, 1, 2, -250, fl - 2.6, -560, -250, fl - 2.6, -760, 2);
    lineL(bd, 1, 2,  260, fl - 2.6, -560,  260, fl - 2.6, -760, 2);

    // meja kecil + benda di atasnya
    prism(color(110, 76, 40), 120, fl, -480, 70, 50, 70, 0);
    prism(color(220, 200, 160), 120, fl - 50, -480, 20, 18, 20, 0);
    prism(color(150, 60, 50), 135, fl - 50, -470, 14, 8, 22, 0.5);

    // noda lantai
    stain(color(88, 78, 64), -100, -300, 55);
    stain(color(88, 78, 64), 200, -520, 70);
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

    // ---- detail tambahan ----
    trim(color(40, 86, 52));
    wainscot(color(44, 96, 62), 80);
    gridH(color(30, 70, 44), fl - 0.5, -wx, wx, -30, zb, 90, 90, 1);       // ubin lantai

    // karpet runner di tengah
    quadN(color(24, 58, 42), 1, 2, 8, -110, fl - 1, -40, 110, fl - 1, -40, 110, fl - 1, zb, -110, fl - 1, zb);
    lineL(color(120, 176, 130), 1, 2, -100, fl - 2, -40, -100, fl - 2, zb, 8);
    lineL(color(120, 176, 130), 1, 2,  100, fl - 2, -40,  100, fl - 2, zb, 8);

    // list lengkung + lampu dinding
    for (int i = 0; i < 5; i++) {
      float zF = -350 - i * 450;
      archTrim(color(124, 184, 132), zF, 0, 170, -70, 22, 16);
      sconce(-310, zF);
      sconce( 310, zF);
    }

    // strip lampu plafon
    addLamp(0, ce + 20, -700, 0.9, 500, 0.80, 1.0, 0.85);
    addLamp(0, ce + 20, -1500, 0.7, 500, 0.80, 1.0, 0.85);
    panel(0, -700, 28, 130, color(200, 235, 205));
    panel(0, -1500, 28, 130, color(190, 225, 195));
  }

  // lampu dinding kecil
  void sconce(float x, float zF) {
    prism(color(40, 62, 46), x, -35, zF + 5, 26, 34, 10, 0);
    quadFlat(color(225, 255, 230), x - 8, -62, zF + 10.5, x + 8, -62, zF + 10.5, x + 8, -48, zF + 10.5, x - 8, -48, zF + 10.5);
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

    // ---- detail tambahan ----
    trim(color(34, 84, 104));
    gridH(color(150, 70, 112), fl - 1.6, -420, 420, -100, zb, 70, 70, 1);   // garis puzzle mat
    lineL(color(232, 140, 180), 1, 3, -420, fl - 1.8, -100, 420, fl - 1.8, -100, 8);
    lineL(color(232, 140, 180), 1, 3, -420, fl - 1.8, zb, 420, fl - 1.8, zb, 8);
    lineL(color(232, 140, 180), 1, 3, -420, fl - 1.8, -100, -420, fl - 1.8, zb, 4);
    lineL(color(232, 140, 180), 1, 3,  420, fl - 1.8, -100,  420, fl - 1.8, zb, 4);

    // pita warna di dinding samping
    quadN(color(200, 60, 60), 0.9, 4, 1, -wx + 0.8, -75, 0, -wx + 0.8, -75, zb, -wx + 0.8, -55, zb, -wx + 0.8, -55, 0);
    quadN(color(200, 60, 60), 0.8, 4, 1,  wx - 0.8, -75, 0,  wx - 0.8, -75, zb,  wx - 0.8, -55, zb,  wx - 0.8, -55, 0);
    quadN(color(228, 190, 40), 0.9, 4, 1, -wx + 0.8, -50, 0, -wx + 0.8, -50, zb, -wx + 0.8, -40, zb, -wx + 0.8, -40, 0);
    quadN(color(228, 190, 40), 0.8, 4, 1,  wx - 0.8, -50, 0,  wx - 0.8, -50, zb,  wx - 0.8, -40, zb,  wx - 0.8, -40, 0);

    // lampu plafon bulat
    recessed(0, -180, 44);
    recessed(-300, -150, 32);
    recessed(300, -150, 32);
    recessed(-200, -330, 28);
    recessed(200, -330, 28);

    // rak mainan di dinding kiri
    prism(color(190, 130, 60), -wx + 30, fl, -240, 44, 110, 210, 0);
    prism(color(226, 80, 70), -wx + 30, fl - 110, -300, 26, 24, 26, 0.3);
    prism(color(70, 150, 200), -wx + 30, fl - 110, -240, 26, 30, 26, 0);
    prism(color(240, 200, 60), -wx + 30, fl - 110, -180, 26, 20, 26, -0.4);

    // balok huruf berserakan
    prism(color(226, 80, 70), -230, fl, -260, 36, 36, 36, 0.4);
    prism(color(70, 150, 200), -170, fl, -300, 36, 36, 36, -0.3);
    prism(color(240, 200, 60), 260, fl, -330, 36, 36, 36, 0.8);
    prism(color(90, 180, 90), 310, fl, -270, 36, 36, 36, 0.1);

    // bola mainan
    ball(color(210, 50, 50), -330, -180, 22);
    ball(color(60, 150, 220), 350, -200, 18);
    ball(color(240, 200, 50), 150, -340, 16);
  }

  // =====================================================================
  //  PEMBANTU: CAHAYA
  // =====================================================================
  void addLamp(float x, float y, float z, float inten, float rad, float r, float gr, float b) {
    if (nL >= 8) return;
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

  color mul(color c, float f) {
    return color(constrain(red(c) * f, 0, 255), constrain(green(c) * f, 0, 255), constrain(blue(c) * f, 0, 255));
  }

  // simpan glow lampu plafon untuk digambar di akhir (additive)
  void addGlow(float cx, float cz, float rx, float rz, color c) {
    if (nG >= 10) return;
    gX[nG] = cx; gZ[nG] = cz; gRX[nG] = rx; gRZ[nG] = rz;
    gR[nG] = red(c); gG[nG] = green(c); gB[nG] = blue(c);
    nG++;
  }

  void glows() {
    g.hint(DISABLE_DEPTH_MASK);
    g.blendMode(ADD);
    float y = ce + 1.0;
    for (int i = 0; i < nG; i++) {
      float a = 90 * gelap * pulse;
      g.beginShape(TRIANGLE_FAN);
      g.fill(gR[i], gG[i], gB[i], a);
      g.vertex(gX[i], y, gZ[i]);
      for (int j = 0; j <= 20; j++) {
        float an = TWO_PI * j / 20;
        g.fill(gR[i], gG[i], gB[i], 0);
        g.vertex(gX[i] + cos(an) * gRX[i], y, gZ[i] + sin(an) * gRZ[i]);
      }
      g.endShape();
    }
    g.blendMode(BLEND);
    g.hint(ENABLE_DEPTH_MASK);
  }

  // debu halus melayang di udara
  void dust(int n) {
    float len = -zb;
    g.strokeWeight(2);
    for (int i = 0; i < n; i++) {
      float x = lerp(-wx * 0.85, wx * 0.85, rnd(i, 31)) + sin(tp * 0.35 + i) * 14;
      float y = lerp(ce + 20, fl - 10, rnd(i, 32)) + sin(tp * 0.5 + i * 1.7) * 10;
      float z = -80 - ((rnd(i, 33) * len + tp * 6) % max(len - 120, 50));
      g.stroke(lit(color(255, 250, 225), 1.7, x, y, z));
      g.point(x, y, z);
    }
    g.noStroke();
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

  // garis kena cahaya, dipecah seg bagian (warna per-vertex)
  void lineL(color c, float sh, float wgt,
             float x1, float y1, float z1, float x2, float y2, float z2, int seg) {
    g.strokeWeight(wgt);
    g.beginShape(LINES);
    for (int i = 0; i < seg; i++) {
      float t0 = i / (float) seg, t1 = (i + 1) / (float) seg;
      float ax = lerp(x1, x2, t0), ay = lerp(y1, y2, t0), az = lerp(z1, z2, t0);
      float bx = lerp(x1, x2, t1), by = lerp(y1, y2, t1), bz = lerp(z1, z2, t1);
      g.stroke(lit(c, sh, ax, ay, az)); g.vertex(ax, ay, az);
      g.stroke(lit(c, sh, bx, by, bz)); g.vertex(bx, by, bz);
    }
    g.endShape();
    g.noStroke();
  }

  // cangkang ruangan: lantai, plafon, dinding kiri/kanan/belakang
  void shell(color floorC, color ceilC, color wallC, color backC) {
    shell(floorC, ceilC, wallC, backC, true);
  }

  // back = false -> dinding belakang tidak digambar (dipakai ruang 3 yang punya alcove)
  void shell(color floorC, color ceilC, color wallC, color backC, boolean back) {
    backWall = back;
    quadN(floorC, 1.0, 12, 12, -wx, fl, 0,  wx, fl, 0,  wx, fl, zb, -wx, fl, zb);
    quadN(ceilC,  0.9, 8, 8,  -wx, ce, 0,  wx, ce, 0,  wx, ce, zb, -wx, ce, zb);
    quadN(wallC,  0.8, 12, 4,  -wx, ce, 0, -wx, ce, zb, -wx, fl, zb, -wx, fl, 0);
    quadN(wallC,  0.7, 12, 4,   wx, ce, 0,  wx, ce, zb,  wx, fl, zb,  wx, fl, 0);
    if (back) quadN(backC,  0.9, 8, 4,   -wx, ce, zb,  wx, ce, zb,  wx, fl, zb, -wx, fl, zb);
    contactShadows();
  }

  // bayangan gelap lembut di pertemuan lantai/plafon dengan dinding
  void contactShadows() {
    float s = 70;
    float yf = fl - 0.6, yc = ce + 0.6;
    g.beginShape(QUADS);
    // lantai kiri / kanan
    g.fill(0, 130); g.vertex(-wx, yf, 0);
    g.fill(0, 130); g.vertex(-wx, yf, zb);
    g.fill(0, 0);   g.vertex(-wx + s, yf, zb);
    g.fill(0, 0);   g.vertex(-wx + s, yf, 0);
    g.fill(0, 120); g.vertex(wx, yf, 0);
    g.fill(0, 120); g.vertex(wx, yf, zb);
    g.fill(0, 0);   g.vertex(wx - s, yf, zb);
    g.fill(0, 0);   g.vertex(wx - s, yf, 0);
    // plafon kiri / kanan
    g.fill(0, 150); g.vertex(-wx, yc, 0);
    g.fill(0, 150); g.vertex(-wx, yc, zb);
    g.fill(0, 0);   g.vertex(-wx + s, yc, zb);
    g.fill(0, 0);   g.vertex(-wx + s, yc, 0);
    g.fill(0, 150); g.vertex(wx, yc, 0);
    g.fill(0, 150); g.vertex(wx, yc, zb);
    g.fill(0, 0);   g.vertex(wx - s, yc, zb);
    g.fill(0, 0);   g.vertex(wx - s, yc, 0);
    if (backWall) {
      g.fill(0, 130); g.vertex(-wx, yf, zb);
      g.fill(0, 130); g.vertex(wx, yf, zb);
      g.fill(0, 0);   g.vertex(wx, yf, zb + s);
      g.fill(0, 0);   g.vertex(-wx, yf, zb + s);
      g.fill(0, 150); g.vertex(-wx, yc, zb);
      g.fill(0, 150); g.vertex(wx, yc, zb);
      g.fill(0, 0);   g.vertex(wx, yc, zb + s);
      g.fill(0, 0);   g.vertex(-wx, yc, zb + s);
    }
    // sudut dinding kiri/kanan dengan dinding belakang (vertikal)
    if (backWall) {
      float zz = zb + 0.6;
      g.fill(0, 110); g.vertex(-wx, ce, zz);
      g.fill(0, 0);   g.vertex(-wx + s, ce, zz);
      g.fill(0, 0);   g.vertex(-wx + s, fl, zz);
      g.fill(0, 110); g.vertex(-wx, fl, zz);
      g.fill(0, 110); g.vertex(wx, ce, zz);
      g.fill(0, 0);   g.vertex(wx - s, ce, zz);
      g.fill(0, 0);   g.vertex(wx - s, fl, zz);
      g.fill(0, 110); g.vertex(wx, fl, zz);
    }
    g.endShape();
  }

  // panel lampu plafon (emisif) + bingkai + pembagi + glow
  void panel(float cx, float cz, float hw, float hd, color c) {
    float fw = 6;
    quadN(color(70, 70, 64), 1, 2, 2,
          cx - hw - fw, ce + 0.9, cz - hd - fw,  cx + hw + fw, ce + 0.9, cz - hd - fw,
          cx + hw + fw, ce + 0.9, cz + hd + fw,  cx - hw - fw, ce + 0.9, cz + hd + fw);
    float y = ce + 1.5;
    quadFlat(c, cx - hw, y, cz - hd, cx + hw, y, cz - hd, cx + hw, y, cz + hd, cx - hw, y, cz + hd);
    g.strokeWeight(2);
    g.stroke(mul(c, 0.55));
    g.line(cx, y + 0.3, cz - hd, cx, y + 0.3, cz + hd);
    g.line(cx - hw, y + 0.3, cz, cx + hw, y + 0.3, cz);
    g.noStroke();
    addGlow(cx, cz, hw * 4.0, hd * 4.0, c);
  }

  // lampu plafon bulat
  void recessed(float cx, float cz, float r) {
    ring(color(60, 100, 112), 1, cx, ce + 1.0, cz, r, r + 7, 20, 1);
    g.beginShape(TRIANGLE_FAN);
    g.fill(255, 248, 232);
    g.vertex(cx, ce + 1.5, cz);
    for (int i = 0; i <= 20; i++) {
      float a = TWO_PI * i / 20;
      g.vertex(cx + r * cos(a), ce + 1.5, cz + r * sin(a));
    }
    g.endShape();
    addGlow(cx, cz, r * 4.0, r * 4.0, color(255, 245, 230));
  }

  // ventilasi plafon
  void vent(float cx, float cz, float w, float d) {
    float y = ce + 1.2;
    quadFlat(color(6), cx - w, y, cz - d, cx + w, y, cz - d, cx + w, y, cz + d, cx - w, y, cz + d);
    g.strokeWeight(2);
    g.stroke(lit(color(110), 1, cx, ce, cz));
    for (int i = -2; i <= 2; i++) g.line(cx - w, y + 0.4, cz + i * d * 0.4, cx + w, y + 0.4, cz + i * d * 0.4);
    g.noStroke();
  }

  // noda gelap di lantai
  void stain(color c, float cx, float cz, float r) {
    disc(c, 1, cx, fl - 1.2, cz, r, 14, 1);
  }

  // grid garis horizontal: y tetap, x dari x0..x1 (garis sepanjang z), z dari zA ke zB (garis sepanjang x)
  void gridH(color c, float y, float x0, float x1, float zA, float zB, float sx, float sz, float wgt) {
    for (float x = x0 + sx; x < x1 - 1; x += sx)
      lineL(c, 1, wgt, x, y, 0, x, y, zB, max(1, (int) (abs(zB) / 300)));
    for (float z = zA; z > zB + 1; z -= sz)
      lineL(c, 1, wgt, x0, y, z, x1, y, z, max(1, (int) ((x1 - x0) / 300)));
  }

  // plint + list plafon (crown)
  void trim(color c) {
    prismSub = 6;
    prism(c, -wx + 4, fl, zb / 2, 8, 16, -zb, 0);
    prism(c,  wx - 4, fl, zb / 2, 8, 16, -zb, 0);
    prism(c, -wx + 4, ce + 9, zb / 2, 8, 9, -zb, 0);
    prism(c,  wx - 4, ce + 9, zb / 2, 8, 9, -zb, 0);
    prismSub = 4;
    if (backWall) {
      prism(c, 0, fl, zb + 4, 2 * wx, 16, 8, 0);
      prism(c, 0, ce + 9, zb + 4, 2 * wx, 9, 8, 0);
    }
    prismSub = 2;
  }

  // wainscot (panel bawah dinding) + rel
  void wainscot(color c, float h) {
    float yt = fl - h;
    quadN(c, 0.8, 6, 2, -wx + 0.8, yt, 0, -wx + 0.8, yt, zb, -wx + 0.8, fl, zb, -wx + 0.8, fl, 0);
    quadN(c, 0.7, 6, 2,  wx - 0.8, yt, 0,  wx - 0.8, yt, zb,  wx - 0.8, fl, zb,  wx - 0.8, fl, 0);
    color rail = mul(c, 1.4);
    lineL(rail, 0.9, 3, -wx + 1.2, yt, 0, -wx + 1.2, yt, zb, 6);
    lineL(rail, 0.8, 3,  wx - 1.2, yt, 0,  wx - 1.2, yt, zb, 6);
    if (backWall) {
      quadN(c, 0.9, 4, 2, -wx, yt, zb + 0.8, wx, yt, zb + 0.8, wx, fl, zb + 0.8, -wx, fl, zb + 0.8);
      lineL(rail, 0.9, 3, -wx, yt, zb + 1.2, wx, yt, zb + 1.2, 4);
    }
  }

  // garis vertikal motif wallpaper di dinding samping (x tetap, sepanjang z)
  void stripesZ(float x, float za, float zb2, color c, float step) {
    for (float z = za - 10; z > zb2; z -= step)
      lineL(c, 0.8, 2, x, ce, z, x, fl, z, 1);
  }

  // garis vertikal motif wallpaper di dinding belakang (z tetap, sepanjang x)
  void stripesX(float z, float xa, float xb, color c, float step) {
    for (float x = xa + 10; x < xb; x += step)
      lineL(c, 0.8, 2, x, ce, z, x, fl, z, 1);
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
      quadN(c, sh, prismSub, 2, px[i], yb, pz[i], px[j], yb, pz[j], px[j], yt, pz[j], px[i], yt, pz[i]);
    }
    quadN(c, 1.0, prismSub, prismSub, px[0], yt, pz[0], px[1], yt, pz[1], px[2], yt, pz[2], px[3], yt, pz[3]);
  }

  // bola mainan sederhana (dengan highlight)
  void ball(color c, float cx, float cz, float r) {
    g.pushMatrix();
    g.translate(cx, fl - r, cz);
    g.fill(lit(c, 0.9, cx, fl - r, cz));
    g.sphereDetail(14);
    g.sphere(r);
    g.translate(-r * 0.3, -r * 0.4, r * 0.55);
    g.fill(lit(mul(c, 1.6), 1.2, cx, fl - r * 1.4, cz + r * 0.5));
    g.sphere(r * 0.28);
    g.popMatrix();
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

  // list timbul di sekeliling lengkung (setengah cincin + dua tiang)
  void archTrim(color c, float zF, float cx, float a, float ys, float w, int seg) {
    float zr = zF + 1.5;
    g.beginShape(QUADS);
    for (int i = 0; i < seg; i++) {
      float a0 = PI * i / seg, a1 = PI * (i + 1) / seg;
      v(c, 1, cx + a * cos(a0), ys - a * sin(a0), zr);
      v(c, 1, cx + a * cos(a1), ys - a * sin(a1), zr);
      v(c, 1, cx + (a + w) * cos(a1), ys - (a + w) * sin(a1), zr);
      v(c, 1, cx + (a + w) * cos(a0), ys - (a + w) * sin(a0), zr);
    }
    g.endShape();
    quadN(c, 1, 2, 3, cx - a - w, ys, zr, cx - a, ys, zr, cx - a, fl, zr, cx - a - w, fl, zr);
    quadN(c, 1, 2, 3, cx + a, ys, zr, cx + a + w, ys, zr, cx + a + w, fl, zr, cx + a, fl, zr);
  }

  // sofa / kursi menghadap +z lokal, diputar yaw
  void sofa(color c, float cx, float cz, float yaw, float len, float dep) {
    part(c, cx, cz, yaw, 0, 0, len, 40, dep);                              // dudukan
    part(c, cx, cz, yaw, 0, -(dep / 2 - 14), len, 100, 28);                // sandaran
    part(c, cx, cz, yaw, -(len / 2 - 14), 0, 28, 68, dep);                 // lengan kiri
    part(c, cx, cz, yaw,  (len / 2 - 14), 0, 28, 68, dep);                 // lengan kanan
    part(mul(c, 0.55), cx, cz, yaw, 0, 0, len - 6, 10, dep - 6);           // kolong gelap di bawah
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
