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
  GUIButton btnPlayPause, btnRestart;
  boolean isPlaying = true;

  ElKontrol(SoundFile lagu, BeatClock clock) {
    this.lagu = lagu;
    this.clock = clock;
    btnPlayPause = new GUIButton(20, 20, 100, 40, "PAUSE", color(200, 50, 50));
    btnRestart   = new GUIButton(130, 20, 100, 40, "RESTART", color(50, 100, 200));
  }

  void show() {
    btnPlayPause.updateHover(mouseX, mouseY);
    btnRestart.updateHover(mouseX, mouseY);
    btnPlayPause.display();
    btnRestart.display();
  }

  void mousePressed() {
    if (btnPlayPause.isClicked(mouseX, mouseY)) {
      if (isPlaying) { lagu.pause(); setPlaying(false); }
      else           { lagu.play();  setPlaying(true); }
    }
    if (btnRestart.isClicked(mouseX, mouseY)) {
      lagu.jump(0);
      clock.reset();
      if (!isPlaying) { lagu.play(); setPlaying(true); }
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
