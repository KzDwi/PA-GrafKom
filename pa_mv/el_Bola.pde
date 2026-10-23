// =====================================================================
//  el_Bola.pde   [ELEMENT 2D]
//  Bola/bentuk di tengah layar yang berdenyut tiap beat dan berganti bentuk.
//
//  bola = new ElBola(100);     // di setup()  (100 = ukuran dasar)
//  bola.show(clock);           // di draw()
// =====================================================================
class ElBola {
  float size, targetSize, baseSize;

  ElBola(float baseSize) {
    this.baseSize = baseSize;
    size = targetSize = baseSize;
  }

  void show(BeatClock t) {
    if (t.newBeat) targetSize = baseSize * 2.5;    // denyut tiap beat
    size       = lerp(size, targetSize, 0.3);
    targetSize = lerp(targetSize, baseSize, 0.1);

    hint(DISABLE_DEPTH_TEST);
    noLights();
    pushMatrix();
    translate(width / 2, height / 2);
    fill(255, 100, 100);
    noStroke();
    rectMode(CENTER);

    int bentuk = t.beat % 4;
    if (bentuk == 0) {
      circle(0, 0, size);
    } else if (bentuk == 1) {
      rect(0, 0, size, size);
    } else if (bentuk == 2) {
      beginShape();
      vertex(0, -size / 2);
      vertex(size / 2, size / 2);
      vertex(-size / 2, size / 2);
      endShape(CLOSE);
    } else {
      rotate(radians(45));
      rect(0, 0, size, size);
    }
    popMatrix();
    hint(ENABLE_DEPTH_TEST);
  }
}
