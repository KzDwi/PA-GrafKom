// =====================================================================
//  el_Kontrol.pde   [ELEMENT 2D - UI]
//  Tombol PLAY/PAUSE dan RESTART di kiri atas + logikanya.
//
//  kontrol = new ElKontrol(lagu, clock);   // setup()
//  kontrol.show();                         // draw()
//  kontrol.mousePressed();                 // di void mousePressed() utama
// =====================================================================
import processing.sound.*;

class ElKontrol {
  SoundFile lagu;
  BeatClock clock;
  GUIButton btnPlayPause, btnRestart, btnCheckpoint;
  boolean isPlaying = true;
  float checkpointSec = 37;   // posisi (detik) yang dipakai tombol RESTART. 0 = awal lagu
  int lastClickMs = -1000;   // anti spam klik (debounce)

  ElKontrol(SoundFile lagu, BeatClock clock) {
    this.lagu = lagu;
    this.clock = clock;
    btnPlayPause = new GUIButton(20, 20, 100, 40, "PAUSE", color(200, 50, 50));
    btnRestart   = new GUIButton(130, 20, 100, 40, "RESTART", color(50, 100, 200));
    btnCheckpoint = new GUIButton(240, 20, 130, 40, "CHECKPOINT", color(200, 130, 20));
  }

  void show() {
    btnPlayPause.updateHover(mouseX, mouseY);
    btnRestart.updateHover(mouseX, mouseY);
    btnCheckpoint.updateHover(mouseX, mouseY);
    btnPlayPause.display();
    btnRestart.display();
    btnCheckpoint.display();

    // info checkpoint aktif (di bawah tombol)
    hint(DISABLE_DEPTH_TEST);
    noLights();
    fill(255, 200);
    textAlign(LEFT, TOP);
    textSize(14);
    float cpBeat = checkpointSec * 1000.0 / clock.beatDuration;
    text("RESTART dari: " + nf(checkpointSec, 0, 2) + " dtk (beat " + nf(cpBeat, 0, 1) + ")   [tombol C = checkpoint]", 20, 68);
    hint(ENABLE_DEPTH_TEST);
  }

  // Simpan posisi lagu SEKARANG sebagai titik RESTART (juga dipanggil dari keyPressed 'c')
  void setCheckpoint() {
    checkpointSec = lagu.position();
  }

  // Restart dari checkpoint & langsung PLAY (aman dipanggil saat pause maupun play)
  void restartFromCheckpoint() {
    // stop() lalu jump(): jump() pada lagu yang berhenti = mulai main dari posisi itu.
    // JANGAN panggil play() lagi setelahnya (itu yang bikin lagu dobel / mulai dari awal).
    lagu.stop();
    clock.reset();
    transitionFx.reset();
    riser.stopNow();
    lagu.jump(checkpointSec);
    lagu.amp(VOLUME);
    setPlaying(true);
  }

  void mousePressed() {
    // Abaikan klik yang terlalu cepat beruntun (penyebab 2 lagu jalan bareng)
    if (millis() - lastClickMs < 200) return;

    if (btnPlayPause.isClicked(mouseX, mouseY)) {
      lastClickMs = millis();
      if (isPlaying) {
        lagu.pause();
        setPlaying(false);
      } else {
        lagu.play();
        lagu.amp(VOLUME);   // play() mereset volume ke 1.0, jadi set ulang
        setPlaying(true);
      }
    }
    if (btnRestart.isClicked(mouseX, mouseY)) {
      lastClickMs = millis();
      restartFromCheckpoint();
    }
    if (btnCheckpoint.isClicked(mouseX, mouseY)) {
      lastClickMs = millis();
      setCheckpoint();
    }
  }

  void setPlaying(boolean p) {
    isPlaying = p;
    btnPlayPause.label     = p ? "PAUSE" : "PLAY";
    btnPlayPause.baseColor = p ? color(200, 50, 50) : color(50, 200, 50);
    btnPlayPause.hoverColor = lerpColor(btnPlayPause.baseColor, color(255), 0.3);
  }
}

class GUIButton {
  float x, y, w, h;
  String label;
  color baseColor, hoverColor;
  boolean isHovered = false;

  GUIButton(float x, float y, float w, float h, String label, color baseColor) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.baseColor = baseColor;
    this.hoverColor = lerpColor(baseColor, color(255), 0.3);
  }

  void updateHover(float mx, float my) { isHovered = isClicked(mx, my); }

  boolean isClicked(float mx, float my) {
    return (mx >= x && mx <= x + w && my >= y && my <= y + h);
  }

  void display() {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    pushMatrix();
    rectMode(CORNER);
    if (isHovered) { fill(hoverColor); stroke(255); }
    else           { fill(baseColor);  noStroke(); }
    strokeWeight(2);
    rect(x, y, w, h, 8);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text(label, x + w / 2, y + h / 2);
    popMatrix();
    hint(ENABLE_DEPTH_TEST);
  }
}
