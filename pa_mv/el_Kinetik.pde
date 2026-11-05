// =====================================================================
//  el_Kinetik.pde   [ELEMENT 2D - ADEGAN "ANAK BERJALAN"]   (ref. video 0:37-0:50)
//  Beat 103-136. Mengikuti video referensi:
//    - layar letterbox abu-abu, di tengah ada pita latar SPIRAL kuning-zaitun berputar,
//      dengan huruf lirik raksasa (abu-abu, memanjang) berderet di atasnya
//    - tiap BEAT muncul 1 anak lagi dari kiri (klon), berjalan bersama, makin penuh
//      sampai memenuhi pita (beat 103 -> 117)
//    - beat 117.5: kolom emas selebar 1/4 layar muncul, 1 anak besar berjalan di dalamnya,
//      kolom LONCAT 1 slot ke kanan tiap beat (0,1,2,3,0,...), klon tetap berjalan di sekitarnya
//
//  GAMBAR (opsional, taruh di folder  data/  ; .png / .jpg / .jpeg boleh):
//    data/img_walk.png    sprite anak berjalan, MENGHADAP KANAN, latar transparan (png)
//    data/img_walk2.png   (opsional) frame langkah ke-2 -> dipakai bergantian dengan img_walk
//    data/img_spiral.png  (opsional) menggantikan spiral buatan di pita tengah
//  Kalau belum ada, dipakai anak buatan (siluet vektor) + spiral buatan.
//
//  kinetik = new ElKinetik(fontJepang);        // setup()
//  kinetik.show(clock, lirik);                 // draw()   (beat 103-135)
// =====================================================================
class ImageSlot {
  PImage img;
  String file, label;
  ImageSlot(String file, String label) {
    this.file = file;
    this.label = label;
    // cari berdasarkan nama tanpa ekstensi: 
    String base = file.substring(0, file.lastIndexOf('.'));
    String[] ext = { ".png", ".jpg", ".jpeg", ".PNG", ".JPG", ".JPEG" };
    for (int i = 0; i < ext.length && img == null; i++) {
      if (new File(dataPath(base + ext[i])).exists()) img = loadImage(base + ext[i]);
    }
  }
  boolean ada() { return img != null; }
}

class ElKinetik {
  PFont font;
  boolean tampilKarakter = true;   // true = anak berjalan tampil, false = hilang (hanya latar)
  float skalaGambar = 0.6;   // 1.0 = ukuran asli, 0.5 = setengah, 0.3 = sepertiga
  ImageSlot sprite1, sprite2, imgSpiral;

  // ---- jadwal (beat) ----
  final float CLONE_START  = 103;     // klon pertama muncul
  final float COLUMN_START = 120;   // kolom emas mulai muncul
  final int   MAX_CLONES   = 15;

  // ---- warna (diambil dari video referensi) ----
  color barC   = color(136, 128, 105);   // abu-abu letterbox
  color spDark = color(106, 89, 45);     // zaitun gelap
  color spGold = color(168, 141, 64);    // emas spiral
  color colC   = color(142, 116, 44);    // kolom emas
  color hoodC  = color(66, 61, 47);
  color hairC  = color(8, 7, 5);
  color skinC  = color(186, 174, 132);
  color lineC  = color(14, 12, 8);

  ElKinetik(PFont font) {
    this.font = font;
    sprite1   = new ImageSlot("img_walk.png",   "anak berjalan, menghadap kiri");
    sprite2   = new ImageSlot("img_walk2.png",  "frame langkah ke-2 (opsional)");
    imgSpiral = new ImageSlot("img_spiral.png", "latar spiral (opsional)");
  }

  // ---------------------------------------------------------------
  void show(BeatClock t, ElLirik lk) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);
    imageMode(CORNER);

    float b = t.beatPos;
    float W = width, H = height;
    float punch = pow(1 - t.frac, 3);
    float top = H * 0.178 - punch * 3;
    float bot = H * 0.817 + punch * 3;

    background(barC);

    // ---- pita tengah: spiral + huruf lirik ----
    fill(spDark);
    rect(0, top, W, bot - top);
    if (imgSpiral.ada()) {
      float s = max(W / imgSpiral.img.width, (bot - top) / imgSpiral.img.height);
      pushMatrix();
      translate(W * 0.45, (top + bot) / 2);
      rotate(b * 0.35);
      imageMode(CENTER);
      image(imgSpiral.img, 0, 0, imgSpiral.img.width * s * 2.2, imgSpiral.img.height * s * 2.2);
      imageMode(CORNER);
      popMatrix();
    } else {
      spiral(W * 0.45, (top + bot) / 2, b, punch);
    }
    kanaRows(t, lk, top, bot - top);

    // ---- bar letterbox menutup sisa spiral di atas & bawah ----
    fill(barC);
    rect(0, 0, W, top);
    rect(0, bot, W, H - bot);

    // ---- klon anak berjalan (1 per beat) ----
    int count = constrain((int) floor(b - CLONE_START) + 1, 0, MAX_CLONES);
    float spacing = W / 13.0;
    for (int i = 0; i < count; i++) {
      float sc  = lerp(0.92, 1.14, i / (float) (MAX_CLONES - 1));
      float x   = 48 + i * spacing;
      float pop = (i == count - 1 && b < CLONE_START + MAX_CLONES) ? punch * 0.12 : 0;
      float sl  = (i == count - 1) ? -punch * 26 : 0;          // klon baru "masuk" dari kiri
      kid(x + sl, H * 0.885, H * 0.74 * sc * (1 + pop), b * PI + i * 0.9);
    }

    // ---- kolom emas loncat per beat ----
    if (b >= COLUMN_START) {
      int slot = ((int) floor(b - COLUMN_START)) % 4;
      float cw = W / 4.0, x0 = slot * cw;
      fill(colC);
      rect(x0, 0, cw, H);
      kid(x0 + cw * 0.5, H * 0.89, H * 0.80 * (1 + punch * 0.03), b * PI);
      if (t.frac < 0.12) {                                       // kilat tipis saat loncat
        fill(255, 240, 200, 70 * (1 - t.frac / 0.12));
        rect(x0, 0, cw, H);
      }
    }

    hint(ENABLE_DEPTH_TEST);
  }

  // ---------------------------------------------------------------
  //  Spiral ganda berputar (pita emas di atas zaitun gelap)
  // ---------------------------------------------------------------
  void spiral(float cx, float cy, float b, float punch) {
    float spin  = b * 0.8;
    float pitch = 190 * (1 + punch * 0.03);
    float hw    = 24;                                  // setengah lebar lengan
    fill(spGold);
    noStroke();
    for (int arm = 0; arm < 2; arm++) {
      beginShape(QUAD_STRIP);
      for (float th = 0.3; th < 34; th += 0.11) {
        float r = th * pitch / TWO_PI;
        float a = th + spin + arm * PI;
        vertex(cx + (r - hw) * cos(a), cy + (r - hw) * sin(a));
        vertex(cx + (r + hw) * cos(a), cy + (r + hw) * sin(a));
      }
      endShape();
    }
  }

  // ---------------------------------------------------------------
  //  Dua baris huruf lirik raksasa (abu-abu, dipipihkan/ditinggikan) di atas spiral
  // ---------------------------------------------------------------
  void kanaRows(BeatClock t, ElLirik lk, float top, float h) {
    String cur = "";
    for (int i = 0; i < lk.lirik.length; i++) {
      if (lk.lirikBeat[i] >= 104 && t.inBeat(lk.lirikBeat[i], lk.lirikBeat[i] + lk.durasiLirik[i])) cur = lk.lirik[i];
    }
    cur = cur.replace(" ", "").replace("　", "");
    if (cur.length() == 0) cur = "くりかえす";
    int n = cur.length();

    textFont(font);
    textAlign(CENTER, CENTER);
    float sp = 92;
    float scroll = t.beatPos * 22;
    int shift = (int) floor(scroll / sp);
    float fx = scroll - shift * sp;
    fill(150, 142, 116, 200);
    for (int row = 0; row < 2; row++) {
      for (int k = -1; k < width / sp + 2; k++) {
        int idx = ((k + shift + row * 2) % n + n) % n;
        String ch = cur.substring(idx, idx + 1);
        pushMatrix();
        translate(k * sp - fx, top + h * (row == 0 ? 0.30 : 0.80));
        if (row == 0) { scale(0.62, 1.7); textSize(185); }
        else          { scale(0.80, 1.15); textSize(170); }
        text(ch, 0, 0);
        popMatrix();
      }
    }
  }

  // ---------------------------------------------------------------
  //  Satu anak berjalan menghadap kanan. cx = tengah badan, footY = tapak kaki,
  //  h = tinggi total (px), ph = fase langkah (radian)
  // ---------------------------------------------------------------
  void kid(float cx, float footY, float h, float ph) {
    if (!tampilKarakter) return;
    if (sprite1.ada()) {
      PImage im = (sprite2.ada() && sin(ph) > 0) ? sprite2.img : sprite1.img;
      float hh = h * skalaGambar;                  // tinggi setelah dikecilkan
      float s  = hh / im.height;
      image(im, cx - im.width * s / 2, footY - hh, im.width * s, hh);
      return;
    }
    float u = h / 100.0;
    pushMatrix();
    translate(cx, footY - abs(sin(ph)) * 1.6 * u);
    strokeJoin(ROUND);

    // kaki (2): paha + betis, outline hitam lalu kulit
    float hipY = -40 * u;
    for (int leg = 0; leg < 2; leg++) {
      float p  = ph + leg * PI;
      float a1 = sin(p) * 0.55;
      float kx = 20 * u * sin(a1),  ky = hipY + 20 * u * cos(a1);
      float a2 = a1 - max(0, cos(p)) * 0.9;
      float ax = kx + 20 * u * sin(a2), ay = ky + 20 * u * cos(a2);
      stroke(lineC); strokeWeight(7.5 * u);
      line(0, hipY, kx, ky); line(kx, ky, ax, ay);
      stroke(skinC); strokeWeight(5 * u);
      line(0, hipY, kx, ky); line(kx, ky, ax, ay);
      stroke(lineC); strokeWeight(1.2 * u); fill(skinC);
      ellipse(ax + 3 * u, ay, 11 * u, 4.5 * u);                  // telapak kaki
    }
    // celana pendek
    noStroke(); fill(lineC);
    rect(-13 * u, -46 * u, 26 * u, 8 * u);
    // hoodie besar
    stroke(lineC); strokeWeight(1.6 * u); fill(hoodC);
    ellipse(-2 * u, -62 * u, 46 * u, 50 * u);
    ellipse(13 * u, -54 * u, 26 * u, 13 * u);                    // lengan menjulur ke depan
    ellipse(6 * u, -76 * u, 17 * u, 12 * u);                     // kerah tinggi
    // kepala
    noStroke(); fill(hairC);
    ellipse(2 * u, -86 * u, 36 * u, 34 * u);
    triangle(-16 * u, -84 * u, -27 * u, -68 * u, -9 * u, -74 * u);   // rambut belakang
    fill(skinC);
    ellipse(12 * u, -83 * u, 15 * u, 13 * u);
    fill(120, 115, 85);
    ellipse(15 * u, -84 * u, 5 * u, 5 * u);                      // mata
    fill(hairC);
    ellipse(8 * u, -92 * u, 28 * u, 12 * u);                     // poni
    popMatrix();
    noStroke();
    strokeWeight(1);
  }
}
