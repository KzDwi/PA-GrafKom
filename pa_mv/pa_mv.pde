import processing.sound.*;
SoundFile lagu;
PFont fontJepang;

AudioBeatManager audio;
VisualBeatObject bola;
Backroom ruangan;
PolyrhythmUI uiPoli;

// 1. Deklarasi variabel tombol
GUIButton btnPlayPause;
GUIButton btnRestart;

boolean isPlaying = true; // Status lagu
int lastBeat = -1;
int lastSubBeat = -1;

void setup() {
  size(720, 900, P3D);
  surface.setResizable(true);
  surface.setLocation(100, 50);
  pixelDensity(displayDensity());
  fontJepang = createFont("NotoSansJP-Regular.ttf", 32);
  lagu = new SoundFile(this, "assets/MainSong.mp3");
  lagu.play();
  
  audio = new AudioBeatManager();
  bola = new VisualBeatObject(width/2, height/2, 100);
  ruangan = new Backroom();
  uiPoli = new PolyrhythmUI(width - 205, 10, 200, 60); 
  
  // 2. Inisialisasi tombol di Kiri Atas
  // x=20, y=20, lebar=100, tinggi=40
  btnPlayPause = new GUIButton(20, 20, 100, 40, "PAUSE", color(200, 50, 50));
  btnRestart = new GUIButton(130, 20, 100, 40, "RESTART", color(50, 100, 200));
}

void draw() {
  float posMs = lagu.position() * 1000; 
  
  int currentBeat = audio.getBeat(posMs);
  int currentSubBeat = audio.getSubBeat(posMs);
  int currentQuarterBeat = audio.getQuarterBeat(posMs); 
  int currentEighthBeat = audio.getEighthBeat(posMs);   
  
  if (currentBeat != lastBeat) {
    bola.pulse(); 
    lastBeat = currentBeat;
  }
  
  // 1. Render 3D Background
  ruangan.display(currentSubBeat, currentBeat); 
  
  // 2. Render Bola Utama
  bola.update();
  bola.display(currentBeat);
  
  // 3. Render UI Polyrhythm
  uiPoli.update(currentBeat, currentSubBeat, currentQuarterBeat, currentEighthBeat);
  uiPoli.display();
  
  // 4. Update Hover & Render Tombol GUI
  btnPlayPause.updateHover(mouseX, mouseY);
  btnRestart.updateHover(mouseX, mouseY);
  btnPlayPause.display();
  btnRestart.display();
  
  // Render Teks (Modul 1)
  hint(DISABLE_DEPTH_TEST); 
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(40);
  text("LOOPING THE ROOM", width/2, 100);
  
  // ... (Bagian Lirik biarkan sama persis seperti sebelumnya) ...
  textFont(fontJepang); 
  textSize(30);
  String[] lirik = {
    "引き抜くカセット", "押し込むリセット", "迷い込む迷路", "進めどもダルセーニョ", 
    "ドアの先に僕の背中が見えた", "振り向いた先に希望が見えた", "地獄の果てなどどこにあるのか", "出口はまだなの？",
    "くる", "くるくる", "くるくるくる", "くるくるくるくる",
    "くりかえす", "く り か え す", "く  り  か  え  す", "く　　り　　か　　え　　す",
    "ふら", "ふらふら", "ふらふらふら", "ふらふらふらふら",
    "ふらくたる", "ふ ら く た る", "ふ  ら  く  た  る", "ふ　　ら　　く　　た　　る"
  };
  int[] lirikBeat = {42, 50, 58, 66, 72, 80, 88, 96,104,105,106,107,108,111,114,117,120,121,122,123,124,127,130,133}; 
  int[] durasiLirik = {4, 4, 5, 5, 7, 8, 8, 4, 1,1,1,1,3,3,3,3,1,1,1,1,3,3,3,3}; 

  for (int i = 0; i < lirik.length; i++) {
    if (currentBeat >= lirikBeat[i] && currentBeat < lirikBeat[i] + durasiLirik[i]) {
      text(lirik[i], width/2, height - 120); 
    }
  }
  
  text("Beat: " + currentBeat + " | SubBeat: " + currentSubBeat, width/2, height - 50);
  hint(ENABLE_DEPTH_TEST); 
}

// 5. Fungsi Event Mouse untuk Tombol
void mousePressed() {
  // Cek Klik Play/Pause
  if (btnPlayPause.isClicked(mouseX, mouseY)) {
    if (isPlaying) {
      lagu.pause();
      isPlaying = false;
      btnPlayPause.label = "PLAY";
      btnPlayPause.baseColor = color(50, 200, 50); // Tombol jadi hijau
    } else {
      lagu.play();
      isPlaying = true;
      btnPlayPause.label = "PAUSE";
      btnPlayPause.baseColor = color(200, 50, 50); // Tombol jadi merah
    }
    // Update warna hover agar sesuai warna baru
    btnPlayPause.hoverColor = lerpColor(btnPlayPause.baseColor, color(255), 0.3);
  }
  
  // Cek Klik Restart
  if (btnRestart.isClicked(mouseX, mouseY)) {
    lagu.jump(0); // Kembali ke detik 0
    if (!isPlaying) {
      lagu.play();
      isPlaying = true;
      btnPlayPause.label = "PAUSE";
      btnPlayPause.baseColor = color(200, 50, 50);
      btnPlayPause.hoverColor = lerpColor(btnPlayPause.baseColor, color(255), 0.3);
    }
    lastBeat = -1; // Reset trigger beat
  }
}