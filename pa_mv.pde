import processing.sound.*;
SoundFile lagu;

AudioBeatManager audio;
VisualBeatObject bola;
Backroom ruangan;

int lastBeat = -1;
int lastSubBeat = -1;

void setup() {
  size(720, 900, P3D);
  surface.setResizable(true);
  surface.setLocation(100, 50);
  pixelDensity(displayDensity());
  lagu = new SoundFile(this, "assets/MainSong.mp3");
  lagu.play();
  
  audio = new AudioBeatManager();
  bola = new VisualBeatObject(width/2, height/2, 100);
  ruangan = new Backroom();
}

void draw() {
  // 1. Dapatkan posisi lagu dalam milidetik
  float posMs = lagu.position() * 1000; 
  
  // 2. Hitung beat dan sub-beat
  int currentBeat = audio.getBeat(posMs);
  int currentSubBeat = audio.getSubBeat(posMs);
  
  // 3. Trigger Visual berdasarkan PolyRhythm (Modul 2)
  if (currentBeat != lastBeat) {
    bola.pulse(); // Memicu animasi utama tiap 1 ketukan
    lastBeat = currentBeat;
  }
  
  // 4. Render
  ruangan.display(currentSubBeat); // Background 3D berputar tiap sub-beat
  bola.update();
  bola.display();
  
  // Render Teks (Modul 1)
  hint(DISABLE_DEPTH_TEST); // Agar teks selalu di depan objek 3D
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("LOOPING THE ROOM", width/2, 100);
  
  // Menampilkan BPM dan Beat saat ini (untuk debugging)
  textSize(20);
  text("Beat: " + currentBeat + " | SubBeat: " + currentSubBeat, width/2, height - 50);
  hint(ENABLE_DEPTH_TEST); // Kembalikan ke mode 3D
}
