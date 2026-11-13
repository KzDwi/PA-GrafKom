// =====================================================================
//  el_Polyrhythm.pde   [ELEMENT 2D - UI]
//  Kotak indikator 4 layer ritme (1/1, 1/2, 1/4, 1/8) di pojok kanan atas.
//  Tiap layer berkedip mengikuti ketukan masing-masing.
//
//  Pemakaian:
//    poli = new ElPolyrhythm(200, 60);    // setup()  (lebar, tinggi kotak)
//    poli.show(clock);                    // draw()
// =====================================================================
class ElPolyrhythm {
  float boxW, boxH;                // lebar & tinggi kotak indikator
  float margin = 5, top = 10;      // jarak dari pojok kanan-atas
  float b1 = 0, b2 = 0, b3 = 0, b4 = 0;   // nilai kedip (0..1) tiap layer
  int l1 = -1, l2 = -1, l3 = -1, l4 = -1; // nilai ketukan terakhir tiap layer

  ElPolyrhythm(float w, float h) {
    boxW = w;
    boxH = h;
  }

  void show(BeatClock t) {
    // reset nilai kedip saat ketukan berubah
    if (t.beat        != l1) { b1 = 1; l1 = t.beat; }
    if (t.subBeat     != l2) { b2 = 1; l2 = t.subBeat; }
    if (t.quarterBeat != l3) { b3 = 1; l3 = t.quarterBeat; }
    if (t.eighthBeat  != l4) { b4 = 1; l4 = t.eighthBeat; }

    // pelan-pelan memudar
    b1 = lerp(b1, 0, 0.1); b2 = lerp(b2, 0, 0.1);
    b3 = lerp(b3, 0, 0.1); b4 = lerp(b4, 0, 0.1);

    hint(DISABLE_DEPTH_TEST);
    noLights();
    pushMatrix();
    translate(width - boxW - margin, top);

    // latar kotak
    rectMode(CORNER);
    fill(0, 150);
    stroke(255, 100);
    strokeWeight(2);
    rect(0, 0, boxW, boxH, 10);

    // Layer 1: lingkaran
    noStroke();
    fill(255, 100, 100, 100 + b1 * 155);
    circle(30, boxH / 2, 20 + b1 * 30);

    // Layer 2: kotak
    fill(100, 255, 255, 100 + b2 * 155);
    rect(60, boxH / 2 - 10, 20 + b2 * 20, 20 + b2 * 20);

    // Layer 3: garis vertikal
    stroke(100, 255, 100, 100 + b3 * 155);
    strokeWeight(3);
    float lh = 40 + b3 * 30;
    line(110, boxH / 2 - lh / 2, 110, boxH / 2 + lh / 2);

    // Layer 4: 3 titik mengambang
    noStroke();
    fill(255, 100, 255, 100 + b4 * 155);
    for (int i = 0; i < 3; i++) {
      circle(140 + i * 15, boxH / 2 + sin(frameCount * 0.1 + i) * 10, 5 + b4 * 10);
    }

    // label
    fill(255);
    textSize(10);
    textAlign(LEFT, TOP);
    text("POLYRHYTHM", 5, 5);

    popMatrix();
    hint(ENABLE_DEPTH_TEST);
  }
}