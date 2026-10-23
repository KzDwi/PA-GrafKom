// =====================================================================
//  core_Canvas3D.pde
//  Kanvas 3D terpisah (offscreen). Dipakai SEMUA element 3D supaya
//  depth buffer / kamera / lampu 3D tidak pernah "nembus" element 2D.
//
//  Pola pemakaian di dalam element 3D:
//      Canvas3D cv = new Canvas3D();         // field class
//      PGraphics g = cv.begin();             // awal show()
//      g.background(...); g.box(...); ...    // SEMUA gambar pakai "g."
//      cv.end();                             // akhir show() -> ditempel ke layar
// =====================================================================
class Canvas3D {
  PGraphics pg;
  int antialias;

  Canvas3D() {
    this(4);
  }

  Canvas3D(int antialias) {
    this.antialias = antialias;
  }

  PGraphics begin() {
    // buat ulang kalau belum ada / ukuran window berubah
    if (pg == null || pg.width != width || pg.height != height) {
      pg = createGraphics(width, height, P3D);
      pg.smooth(antialias);
    }
    pg.beginDraw();
    return pg;
  }

  void end() {
    pg.endDraw();
    // tempel sebagai gambar 2D biasa di belakang element 2D
    hint(DISABLE_DEPTH_TEST);
    noLights();
    imageMode(CORNER);
    tint(255);
    image(pg, 0, 0, width, height);
    hint(ENABLE_DEPTH_TEST);
  }
}
