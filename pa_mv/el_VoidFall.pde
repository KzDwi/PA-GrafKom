// =====================================================================
//  el_VoidFall.pde   [ELEMENT 3D & 2D TERPISAH]
//  Adegan "void fall" dengan 4 scene:
//    0 = kubus meledak perlahan (3D)
//    1 = void partikel saja (3D kosong + 2D partikel)
//    2 = lorong 3D berjalan (RoomSegment3D)
//    3 = lorong kelas gelap (3D)
//  show3D() dipanggil di bagian 3D, show2D() di bagian 2D.
// =====================================================================
class ElVoidFall {
  Canvas3D cv3d = new Canvas3D(4);                      // kanvas offscreen 3D (zoom 4x)

  int currentScene = -1;        // scene yang sedang aktif (-1 = belum pernah)
  float sceneStartBeat = 0;     // beatPos saat scene mulai (untuk animasi lokal)
  PImage noiseTex;              // tekstur noise untuk dinding kubus/ruangan

  float boxW = 400;             // lebar kubus utama
  float boxH = 150;             // tinggi kubus utama
  float boxD = 400;             // kedalaman kubus utama

  ArrayList<SharpShard3D>  shatterShards  = new ArrayList<SharpShard3D>();   // pecahan kubus
  ArrayList<VoidParticle2D> voidParticles = new ArrayList<VoidParticle2D>(); // partikel void
  ArrayList<BlinkingStar2D> stars         = new ArrayList<BlinkingStar2D>(); // bintang berkedip
  RoomSegment3D[] roomSegments = new RoomSegment3D[4];                       // segmen lorong 3D

  ElVoidFall() {
    createTexture();
    for (int i = 0; i < 50; i++) voidParticles.add(new VoidParticle2D());
    for (int i = 0; i < 30; i++) stars.add(new BlinkingStar2D());
    for (int i = 0; i < roomSegments.length; i++) roomSegments[i] = new RoomSegment3D(i * 2000 - 4000);
  }

  // buat tekstur noise abu-abu untuk dinding 3D
  void createTexture() {
    noiseTex = createImage(256, 256, RGB);
    noiseTex.loadPixels();
    for(int i = 0; i < noiseTex.pixels.length; i++) {
      float n = random(100, 170);
      noiseTex.pixels[i] = color(n, n, n);
    }
    noiseTex.updatePixels();
  }

  // buat pecahan kubus acak (hanya untuk scene 0)
  void buildPartialShatter() {
    shatterShards.clear();
    for (int i = 0; i < 90; i++) {
      float ox = random(-boxW/2, boxW/2);
      float oy = random(0, boxH/2);
      float oz = random(boxD/2 - 100, boxD/2);
      float sSize = random(25, 70);
      PVector p1 = new PVector(ox, oy, oz);
      PVector p2 = new PVector(ox + random(-sSize, sSize), oy + random(-sSize, sSize), oz + random(-sSize, sSize));
      PVector p3 = new PVector(ox + random(-sSize, sSize), oy + random(-sSize, sSize), oz + random(-sSize, sSize));
      shatterShards.add(new SharpShard3D(p1, p2, p3, this));
    }
  }

  // update state internal scene (reset bila scene berganti atau lagu di-restart mundur)
  void updateLogic(BeatClock t, int scene) {
    if (scene != currentScene || t.beatPos < sceneStartBeat) {
      sceneStartBeat = t.beatPos;
      currentScene = scene;

      if (scene == 0) buildPartialShatter();
      if (scene <= 3) for (VoidParticle2D vp : voidParticles) vp.initRandom(true);
    }
  }

  // =========================================================
  // FUNGSI 1: dipanggil di bagian "1. LATAR 3D"
  // =========================================================
  void show3D(BeatClock t, int scene) {
    updateLogic(t, scene);
    float localBeat = max(0, t.beatPos - sceneStartBeat);

    PGraphics g3 = cv3d.begin();

    if (scene == 3)      g3.background(20, 15, 10);
    else if (scene == 2) g3.background(18, 16, 14);
    else                 g3.background(5, 5, 8);

    g3.hint(ENABLE_DEPTH_TEST);

    if (scene < 3) {
      g3.lights();
      if (scene == 2) {
        g3.ambientLight(110, 105, 100);
        g3.directionalLight(100, 95, 90, 0.2, 0.5, -1);
      } else {
        g3.ambientLight(50, 45, 45);
        g3.pointLight(255, 230, 200, 0, -200, 800);
        g3.directionalLight(100, 100, 120, 0, 1, -1);
      }

      if (scene == 0) {
        // scene 0: kubus meledak perlahan
        g3.perspective(radians(60), (float)width/height, 10, 5000);
        g3.camera(200, -50 + (localBeat * 10), 700,  0, 0, 0,  0, 1, 0);
        drawIntactUpperCube(g3);
        for (SharpShard3D ss : shatterShards) ss.display(g3);
      }
      else if (scene == 2) {
        // scene 2: lorong 3D berjalan (segmen bergerak menuju kamera)
        g3.perspective(radians(65), (float)width/height, 10, 5000);
        g3.camera(50, 30, 1000,   0, -50, 0,   0, 1, 0);
        g3.pushMatrix();

        float moveSpeed = 4.5;
        for (int i = 0; i < roomSegments.length; i++) {
          roomSegments[i].update(moveSpeed);
          roomSegments[i].display(g3, noiseTex);
        }
        g3.popMatrix();

        // tutup sisi kiri & kanan supaya tepi lorong tidak terlihat
        g3.pushMatrix();
        g3.noStroke();
        g3.fill(18, 16, 14, 230);
        g3.translate(4000, 0, 0); g3.rectMode(CENTER); g3.rect(0, 0, 2000, 5000);
        g3.translate(-8000, 0, 0); g3.rect(0, 0, 2000, 5000);
        g3.popMatrix();
      }
    }
    // ==========================================
    // SCENE 3 (CLOCK 3): LORONG KELAS (TETAP GELAP KONSISTEN)
    // ==========================================
    else if (scene == 3) {
      g3.noLights();                                     // sengaja tanpa cahaya supaya gelap konsisten
      g3.perspective(radians(70), (float)width/height, 10, 8000);
      g3.camera(0, 0, 200,   0, 0, -1000,   0, 1, 0);
      drawSchoolHallway(g3, localBeat);
    }

    cv3d.end();
  }

  // =========================================================
  // FUNGSI 2: dipanggil di bagian "2. ELEMENT 2D"
  // =========================================================
  void show2D(BeatClock t) {
    pushStyle();
    hint(DISABLE_DEPTH_TEST);

    if (currentScene <= 2) {
      for (BlinkingStar2D star : stars) { star.update(); star.display(); }
    }

    // kecepatan partikel berbeda per scene
    float particleSpeed = (currentScene == 3) ? 12.0 : ((currentScene == 2) ? 0.3 : 1.5);
    for (VoidParticle2D vp : voidParticles) {
      vp.update(particleSpeed);
      vp.display();
    }

    hint(ENABLE_DEPTH_TEST);
    popStyle();
  }

  // lorong kelas gelap: segmen berulang sepanjang sumbu Z
  void drawSchoolHallway(PGraphics g3, float localBeat) {
    float w = 400;                                       // setengah lebar lorong
    float h = 300;                                       // setengah tinggi lorong
    float moveZ = (localBeat * 80) % 800;                // animasi gerak maju

    g3.pushMatrix();
    g3.translate(0, 0, moveZ);
    g3.noStroke();

    for (int i = -1; i < 6; i++) {
      float z = -i * 800;

      // lantai
      g3.fill(40, 32, 25);
      g3.beginShape(QUADS);
      g3.vertex(-w, h, z); g3.vertex(w, h, z);
      g3.vertex(w, h, z - 800); g3.vertex(-w, h, z - 800);
      g3.endShape();

      // plafon
      g3.fill(50, 45, 40);
      g3.beginShape(QUADS);
      g3.vertex(-w, -h, z); g3.vertex(w, -h, z);
      g3.vertex(w, -h, z - 800); g3.vertex(-w, -h, z - 800);
      g3.endShape();

      // dinding kiri & kanan
      g3.fill(70, 60, 50);
      g3.beginShape(QUADS);
      g3.vertex(-w, -h, z); g3.vertex(-w, h, z);
      g3.vertex(-w, h, z - 800); g3.vertex(-w, -h, z - 800);
      g3.vertex(w, -h, z); g3.vertex(w, h, z);
      g3.vertex(w, h, z - 800); g3.vertex(w, -h, z - 800);
      g3.endShape();

      // pintu di dinding kiri
      g3.fill(35, 28, 22);
      g3.beginShape(QUADS);
      g3.vertex(-w + 2, 50, z - 150); g3.vertex(-w + 2, h, z - 150);
      g3.vertex(-w + 2, h, z - 450); g3.vertex(-w + 2, 50, z - 450);
      g3.endShape();

      // pilar di kiri & kanan
      g3.fill(55, 45, 38);
      g3.pushMatrix();
      g3.translate(-w + 10, 0, z); g3.box(20, h * 2, 80);
      g3.translate(w * 2 - 20, 0, 0); g3.box(20, h * 2, 80);
      g3.popMatrix();

      // lampu plafon
      g3.fill(220, 220, 180);
      g3.beginShape(QUADS);
      g3.vertex(-80, -h + 2, z - 300); g3.vertex(80, -h + 2, z - 300);
      g3.vertex(80, -h + 2, z - 500); g3.vertex(-80, -h + 2, z - 500);
      g3.endShape();
    }
    g3.popMatrix();
  }

  // gambar setengah kubus atas (bagian yang belum pecah) di scene 0
  void drawIntactUpperCube(PGraphics g3) {
    g3.noStroke(); g3.textureMode(NORMAL); g3.beginShape(QUADS); g3.texture(noiseTex);
    g3.vertex(-boxW/2, -boxH/2, -boxD/2, 0, 0); g3.vertex( boxW/2, -boxH/2, -boxD/2, 1, 0);
    g3.vertex( boxW/2, -boxH/2,  boxD/2, 1, 1); g3.vertex(-boxW/2, -boxH/2,  boxD/2, 0, 1);
    g3.vertex(-boxW/2, -boxH/2, -boxD/2, 0, 0); g3.vertex( boxW/2, -boxH/2, -boxD/2, 1, 0);
    g3.vertex( boxW/2,  boxH/2,  boxD/2, 1, 1); g3.vertex(-boxW/2,  boxH/2, -boxD/2, 0, 1);
    g3.endShape();
  }
}

// =====================================================================
// KELAS-KELAS PENDUKUNG
// =====================================================================

// Satu segmen lorong 3D berbentuk kotak berlubang (untuk scene 2)
class RoomSegment3D {
  float x;             // posisi X segmen (bergerak ke kanan, lalu loop)
  float w = 2000;      // lebar
  float h = 1500;      // tinggi
  float d = 1000;      // kedalaman
  float t = 100;       // ketebalan dinding

  RoomSegment3D(float startX) { x = startX; }

  void update(float speed) {
    x += speed;
    if (x > w * 2.5) x -= w * 4;    // wrap-around: kembali ke kiri kalau sudah lewat
  }

  void display(PGraphics g3, PImage tex) {
    g3.pushMatrix(); g3.translate(x, 0, -400); g3.noStroke();
    g3.textureMode(NORMAL); g3.beginShape(QUADS); g3.texture(tex);

    // dinding belakang (paling terang)
    g3.tint(100, 100, 100);
    g3.vertex(-w/2, -h/2, -d/2, 0, 0); g3.vertex(w/2, -h/2, -d/2, 1, 0);
    g3.vertex(w/2, h/2, -d/2, 1, 1); g3.vertex(-w/2, h/2, -d/2, 0, 1);

    // plafon (lebih gelap)
    g3.tint(70, 70, 70);
    g3.vertex(-w/2, -h/2, d/2, 0, 0); g3.vertex(w/2, -h/2, d/2, 1, 0);
    g3.vertex(w/2, -h/2, -d/2, 1, 1); g3.vertex(-w/2, -h/2, -d/2, 0, 1);

    // lantai
    g3.tint(90, 90, 90);
    g3.vertex(-w/2, h/2, -d/2, 0, 0); g3.vertex(w/2, h/2, -d/2, 1, 0);
    g3.vertex(w/2, h/2, d/2, 1, 1); g3.vertex(-w/2, h/2, d/2, 0, 1);

    // dinding samping
    g3.tint(85, 85, 85);
    g3.vertex(-w/2, -h/2, d/2, 0, 0); g3.vertex(-w/2, -h/2, -d/2, 1, 0);
    g3.vertex(-w/2, h/2, -d/2, 1, 1); g3.vertex(-w/2, h/2, d/2, 0, 1);

    g3.endShape(); g3.noTint();

    // bingkai gelap di tepi depan segmen
    g3.fill(25, 23, 20); g3.beginShape(QUADS);
    g3.vertex(-w/2, -h/2 - t, d/2); g3.vertex(w/2, -h/2 - t, d/2); g3.vertex(w/2, -h/2, d/2); g3.vertex(-w/2, -h/2, d/2);
    g3.vertex(-w/2, h/2, d/2); g3.vertex(w/2, h/2, d/2); g3.vertex(w/2, h/2 + t, d/2); g3.vertex(-w/2, h/2 + t, d/2);
    g3.vertex(-w/2 - t/2, -h/2 - t, d/2); g3.vertex(-w/2 + t/2, -h/2 - t, d/2); g3.vertex(-w/2 + t/2, h/2 + t, d/2); g3.vertex(-w/2 - t/2, h/2 + t, d/2);
    g3.endShape(); g3.popMatrix();
  }
}

// Satu pecahan segitiga 3D (bagian dari kubus yang meledak)
class SharpShard3D {
  PVector a, b, c, center;              // tiga titik sudut + titik tengah
  float offsetX, offsetY, offsetZ;      // geseran posisi pecahan
  float rotX, rotY, rotZ;               // rotasi acak
  ElVoidFall parent;                    // untuk akses tekstur noise parent

  SharpShard3D(PVector a, PVector b, PVector c, ElVoidFall parent) {
    this.a = a; this.b = b; this.c = c; this.parent = parent;
    center = PVector.add(a, b).add(c).div(3);
    offsetX = random(-40, 40); offsetY = random(0, 100); offsetZ = random(-40, 40);
    rotX = random(-0.4, 0.4); rotY = random(-0.4, 0.4); rotZ = random(-0.4, 0.4);
  }

  void display(PGraphics g3) {
    g3.pushMatrix(); g3.translate(center.x + offsetX, center.y + offsetY, center.z + offsetZ);
    g3.translate(-center.x, -center.y, -center.z); g3.rotateX(rotX); g3.rotateY(rotY); g3.rotateZ(rotZ);
    g3.noStroke(); g3.textureMode(NORMAL); g3.beginShape(TRIANGLES); g3.texture(parent.noiseTex);
    g3.vertex(a.x, a.y, a.z, 0, 0); g3.vertex(b.x, b.y, b.z, 1, 0); g3.vertex(c.x, c.y, c.z, 0.5, 1);
    g3.endShape(); g3.popMatrix();
  }
}

// Partikel void 2D: segitiga kecil yang melayang naik
class VoidParticle2D {
  float x, y;               // posisi layar
  float pseudoZ;            // "kedalaman" palsu (untuk skala + kecepatan)
  float rot, rotSpeed;      // rotasi saat ini & kecepatannya
  float vy;                 // kecepatan vertikal

  VoidParticle2D() { initRandom(true); }

  // reset posisi & properti partikel. `onScreen` = true -> di atas layar (awal),
  // false -> di bawah layar (untuk respawn agar muncul dari bawah).
  void initRandom(boolean onScreen) {
    x = random(-width, width * 2);
    y = onScreen ? random(-height, height * 2) : random(height + 100, height + 500);
    pseudoZ = random(0.5, 3.0); vy = random(-5.0, -2.0) * pseudoZ;
    rot = random(TWO_PI); rotSpeed = random(-0.05, 0.05);
  }

  void update(float speedMult) {
    y += (vy * speedMult); rot += rotSpeed;
    if (y < -200) initRandom(false);
  }

  void display() {
    pushMatrix(); translate(x, y); rotate(rot); scale(pseudoZ); noStroke(); fill(130, 130, 130, 200);
    beginShape(); vertex(0, -10); vertex(-7, 7); vertex(7, 7); endShape(CLOSE); popMatrix();
  }
}

// Bintang 2D dengan kedipan (alpha mengikuti sin)
class BlinkingStar2D {
  float x, y;               // posisi
  float size;               // ukuran bintang
  float phase, speed;       // fase kedipan & kecepatannya

  BlinkingStar2D() {
    x = random(0, width); y = random(0, height); size = random(2, 6);
    phase = random(TWO_PI); speed = random(0.02, 0.08);
  }

  void update() { phase += speed; }

  void display() {
    float alpha = map(sin(phase), -1, 1, 30, 200);
    noStroke(); fill(255, alpha); pushMatrix(); translate(x, y);
    beginShape(); vertex(0, -size); vertex(size/4, -size/4); vertex(size, 0); vertex(size/4, size/4);
    vertex(0, size); vertex(-size/4, size/4); vertex(-size, 0); vertex(-size/4, -size/4); endShape(CLOSE);
    popMatrix();
  }
}