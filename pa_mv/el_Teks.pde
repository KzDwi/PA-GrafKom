// =====================================================================
//  el_Teks.pde   [ELEMENT 2D - TEKS]
//  ElJudul  : judul di atas layar
//  ElLirik  : lirik per beat (data lirik ada di dalam class ini)
//  ElDebug  : teks beat/subbeat di bawah layar
//
//  judul = new ElJudul(fontJepang, "LOOPING THE ROOM");   // setup()
//  lirik = new ElLirik(fontJepang);
//  debug = new ElDebug(fontJepang);
//  judul.show(clock);  lirik.show(clock);  debug.show(clock);   // draw()
// =====================================================================
class ElJudul {
  PFont font;
  String isi;

  ElJudul(PFont font, String isi) {
    this.font = font;
    this.isi = isi;
  }

  void show(BeatClock t) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    textFont(font);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(40);
    text(isi, width / 2, 100);
    hint(ENABLE_DEPTH_TEST);
  }
}

class ElLirik {
  PFont font;

  String[] lirik = {
    "引き抜くカセット", "押し込むリセット", "迷い込む迷路", "進めどもダルセーニョ",
    "ドアの先に僕の背中が見えた", "振り向いた先に希望が見えた", "地獄の果てなどどこにあるのか", "出口はまだなの？",
    "くる", "くるくる", "くるくるくる", "くるくるくるくる",
    "くりかえす", "く り か え す", "く  り  か  え  す", "く　　り　　か　　え　　す",
    "ふら", "ふらふら", "ふらふらふら", "ふらふらふらふら",
    "ふらくたる", "ふ ら く た る", "ふ  ら  く  た  る", "ふ　　ら　　く　　た　　る"
  };
  int[] lirikBeat   = {42, 50, 58, 66, 72, 80, 88, 96, 104, 105, 106, 107, 108, 111, 114, 117, 120, 121, 122, 123, 124, 127, 130, 133};
  int[] durasiLirik = { 4,  4,  5,  5,  7,  8,  8,  4,   1,   1,   1,   1,   3,   3,   3,   3,   1,   1,   1,   1,   3,   3,   3,   3};

  ElLirik(PFont font) {
    this.font = font;
  }

  void show(BeatClock t) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    textFont(font);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(30);
    for (int i = 0; i < lirik.length; i++) {
      if (t.inBeat(lirikBeat[i], lirikBeat[i] + durasiLirik[i])) {
        text(lirik[i], width / 2, height - 120);
      }
    }
    hint(ENABLE_DEPTH_TEST);
  }
}

class ElDebug {
  PFont font;

  ElDebug(PFont font) {
    this.font = font;
  }

  void show(BeatClock t) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    textFont(font);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(30);
    text("Beat: " + t.beat + " | SubBeat: " + t.subBeat, width / 2, height - 50);
    hint(ENABLE_DEPTH_TEST);
  }
}
