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
//  GAMBAR (opsional, taruh di folder assets/):
//    pose1.png - pose4.png   fase awal berganti tiap 4 beat; mulai beat 121 disorot bergiliran
//    data/img_spiral.png  (opsional) menggantikan spiral buatan di pita tengah
//  Kalau belum ada, dipakai anak buatan (siluet vektor) + spiral buatan.
//
//  kinetik = new ElKinetik(fontJepang);        // setup()
//  kinetik.show(clock, lirik);                 // draw()   (beat 103-135)
//  kinetik.show(clock, lirik, 128);            // pemakaian ulang: semua jadwal digeser +128 beat (231-263)
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
      String path = sketchPath(base + ext[i]);
      if (new File(path).exists()) img = loadImage(path);
    }
  }
  boolean ada() { return img != null; }
}

class ElKinetik {
  PFont font;
  boolean tampilKana = true;       // true = huruf lirik raksasa di atas spiral (sekarang dimatikan: spiral murni)
  int   ofs = 0;                    // geseran beat (0 = adegan asli 103-136; 128 = pengulangan 231-264)
  boolean tampilKarakter = true;   // true kalau udh ada gambar
  float skalaGambar = 0.9;   // 1.0 = ukuran asli, 0.5 = setengah, 0.3 = sepertiga
  ImageSlot sprite1, sprite2, sprite3, sprite4, imgSpiral;

  // ---- jadwal (beat) ----
  final float CLONE_START  = 104;     // klon pertama muncul
  final float COLUMN_START = 120;   // kolom emas mulai muncul
  final int   MAX_CLONES   = 16;

  // ---- warna (diambil dari video referensi) ----
  color barC   = color(136, 128, 105);   // abu-abu letterbox
  color spDark = color(106, 89, 45);     // zaitun gelap
  color spGold = color(168, 141, 64);    // emas spiral
  color colC   = color(142, 116, 44);    // kolom emas

  // ---- REDUP BERTAHAP (4 tahap, 1 per beat, mulai di beat ABSOLUT dimMulai; -1 = mati) ----
  //  tahap 1: latar gelap, kolom emas tetap terlihat tapi redup
  //  tahap 2: latar makin gelap, kolom emas makin redup
  //  tahap 3: kolom berubah abu-abu gelap
  //  tahap 4: semua hitam, tinggal karakter
  float dimMulai = -1;
  float[] bgMul = { 1, 0.30, 0.18, 0.10, 0 };                 // kecerahan latar tiap tahap
  color[] colTahap = { color(142, 116, 44), color(104, 86, 34), color(64, 54, 28), color(38, 36, 32), color(0) };
  color hoodC  = color(66, 61, 47);
  color hairC  = color(8, 7, 5);
  color skinC  = color(186, 174, 132);
  color lineC  = color(14, 12, 8);

  ElKinetik(PFont font) {
    this.font = font;
    sprite1   = new ImageSlot("assets/pose1.png",   "anak berjalan, menghadap kiri");
    sprite2   = new ImageSlot("assets/pose2.png",  "frame langkah ke-2");
    sprite3   = new ImageSlot("assets/pose3.png",   "anak berjalan, menghadap kiri");
    sprite4   = new ImageSlot("assets/pose4.png",  "frame langkah ke-2");
    imgSpiral = new ImageSlot("img_spiral.png", "latar spiral (opsional)");
  }

  // ---------------------------------------------------------------
  void show(BeatClock t, ElLirik lk) { show(t, lk, 0); }

  void show(BeatClock t, ElLirik lk, int geser) {
    ofs = geser;
    hint(DISABLE_DEPTH_TEST);
    noLights();
    noStroke();
    rectMode(CORNER);
    imageMode(CORNER);

    float b = t.beatPos - ofs;     // beat relatif terhadap adegan
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
      translate(W * 0.5, (top + bot) / 2);
      rotate(b * 0.35);
      imageMode(CENTER);
      image(imgSpiral.img, 0, 0, imgSpiral.img.width * s * 2.2, imgSpiral.img.height * s * 2.2);
      imageMode(CORNER);
      popMatrix();
    } else {
      spiral(W * 0.5, (top + bot) / 2, b, punch);
    }
    if (tampilKana) kanaRows(t, lk, top, bot - top);

    // ---- bar letterbox menutup sisa spiral di atas & bawah ----
    fill(barC);
    rect(0, 0, W, top);
    rect(0, bot, W, H - bot);

    // ---- klon anak berjalan (1 per beat) ----
    int count = constrain((int) floor(b - CLONE_START) + 1, 0, MAX_CLONES);
    float spacing = W / 16.0;
    for (int i = 0; i < count; i++) {
      float x   = 48 + i * spacing;
      boolean entering = i == count - 1 && count < MAX_CLONES;
      float pop = entering ? punch * 0.12 : 0;
      float sl  = entering ? -punch * 26 : 0;
      kid(x + sl, H * 0.885, H * 0.74 * 1.14 * (1 + pop), b * PI + i * 0.9, clonePoseIndex(i));
    }

    // ---- redup bertahap: latar digelapkan, kolom & karakter TIDAK ikut ----
    float L = 0;                                  // 0 normal .. 4 gelap total
    if (dimMulai >= 0 && t.beatPos >= dimMulai) {
      float d  = t.beatPos - dimMulai;
      int   s  = min(3, (int) floor(d));
      float kk = constrain((d - s) / 0.3, 0, 1);  // meredup halus 0.3 beat tiap tahap
      L = min(4, s + kk * kk * (3 - 2 * kk));
    }
    color colNow = colC;
    if (L > 0) {
      int i0 = (int) floor(L), i1 = min(4, i0 + 1);
      float m = lerp(bgMul[i0], bgMul[i1], L - i0);
      noStroke();
      fill(0, 255 * (1 - m));
      rect(0, 0, W, H);
      colNow = lerpColor(colTahap[i0], colTahap[i1], L - i0);
    }

    // ---- kolom emas loncat per beat ----
    if (b >= COLUMN_START) {
      int slot = ((int) floor(b - COLUMN_START)) % 4;
      float cw = W / 4.0, x0 = slot * cw;
      fill(colNow);
      rect(x0, 0, cw, H);
      kid(x0 + cw * 0.5, H * 0.89, H * 0.80 * (1 + punch * 0.03), b * PI, highlightedPoseIndex(b));
      if (t.frac < 0.12 && L < 2.5) {                                       // kilat tipis saat loncat
        fill(255, 240, 200, 70 * (1 - t.frac / 0.12));
        rect(x0, 0, cw, H);
      }
    }

    hint(ENABLE_DEPTH_TEST);
  }

    int clonePoseIndex(int cloneIndex) {
    return cloneIndex / 4;
  }

  int highlightedPoseIndex(float b) {
    int step = (int) floor(b - COLUMN_START);
    int cloneIndex = (step % 4) * 4 + step / 4;
    return cloneIndex / 4;
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
      if (lk.lirikBeat[i] >= 104 + ofs && t.inBeat(lk.lirikBeat[i], lk.lirikBeat[i] + lk.durasiLirik[i])) cur = lk.lirik[i];
    }
    cur = cur.replace(" ", "").replace("　", "");
    if (cur.length() == 0) cur = "くりかえす";
    int n = cur.length();

    textFont(font);
    textAlign(CENTER, CENTER);
    float sp = 92;
    float scroll = (t.beatPos - ofs) * 22;
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
  void kid(float cx, float footY, float h, float ph, int pose) {
    if (!tampilKarakter) return;
    PImage im = pose == 0 ? sprite1.img
               : pose == 1 ? sprite2.img
               : pose == 2 ? sprite3.img
               : pose == 3 ? sprite4.img
               : null;
    if (im != null) {
      float hh = h * skalaGambar;                  // tinggi setelah dikecilkan
      float s  = hh / im.height;
      image(im, cx - im.width * s / 2, footY - hh, im.width * s, hh);
      return;
    }
    float u = h / 100.0;
    pushMatrix();
    translate(cx, footY - abs(sin(ph)) * 1.6 * u);
    strokeJoin(ROUND);
  }
}
