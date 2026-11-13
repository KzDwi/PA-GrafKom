// =====================================================================
//  el_Teks.pde   [ELEMENT 2D - TEKS]
//  ElJudul : judul di atas layar
//  ElLirik : lirik per beat (data lirik ada di dalam class ini)
//  ElDebug : teks beat/subbeat di bawah layar
//
//  Pemakaian:
//    judul = new ElJudul(fontJepang, "LOOPING THE ROOM");   // setup()
//    lirik = new ElLirik(fontJepang);
//    debug = new ElDebug(fontJepang);
//    judul.show(clock); lirik.show(clock); debug.show(clock); // draw()
// =====================================================================
class ElJudul {
  PFont font;        // font yang dipakai untuk judul
  String isi;        // teks judul yang ditampilkan

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
    text(isi, width / 2, 100);                       // judul di tengah-atas layar
    hint(ENABLE_DEPTH_TEST);
  }
}

class ElLirik {
  PFont font;        // font untuk lirik

  // daftar baris lirik (satu baris = satu entri di sini)
  String[] lirik = {
    "引き抜くカセット", "押し込むリセット",
    "迷い込む迷路", "進めどもダルセーニョ",

    "ドアの先に僕の背中が見えた", "振り向いた先に希望が見えた",
    "地獄の果てなどどこにあるのか", "出口はまだなの？",

    "くる", "くるくる", "くるくるくる", "くるくるくるくる",
    "くりかえす", "く り か え す", "く  り  か  え  す", "く　　り　　か　　え　　す",
    "ふら", "ふらふら", "ふらふらふら", "ふらふらふらふら",
    "ふらくたる", "ふ ら く た る", "ふ  ら  く  た  る", "ふ　　ら　　く　　た　　る",

    "空回るソウト", "終わらないロード",
    "鉄臭い酸素", "届かないSOS",

    "落ちてた柘榴で飢えを凌いだ","頭蓋の中から耳鳴りがした",
    "進めど進めど変わりないなら","抗う意味など",

    "くる", "くるくる", "くるくるくる", "くるくるくるくる",
    "くりかえす", "く り か え す", "く  り  か  え  す", "く　　り　　か　　え　　す",
    "ふら", "ふらふら", "ふらふらふら", "ふらふらふらふら",
    "ふらくたる", "ふ ら く た る", "ふ  ら  く  た  る", "ふ　　ら　　く　　た　　る",

    "ああ、扉を開け","意味も忘れ",
    "いかれた夢の奥へ","どこまでも続いてく",

    "くるくるくりかえす"
  };
  // beat mulai tampil untuk masing-masing baris di atas (indeks sama)
  int[] lirikBeat   = {
    42, 50,
    58, 66,
    72, 80,
    88, 96,
    104, 105, 106, 107,
    108, 111, 114, 117,
    120, 121, 122, 123,
    124, 127, 130, 133,
    170, 178,
    186, 194,
    200, 208,
    216, 224,
    232, 233, 234, 235,
    236, 239, 242, 245,
    248, 249, 250, 251,
    252, 255, 258, 261,
    264, 269,
    274, 281,
    292
  };
  // durasi tampil (beat) untuk tiap baris, berpasangan dengan lirikBeat
  int[] durasiLirik = {
    4,  4,
    5,  5,
    7,  8,
    8,  4,
    1,  1,  1,  1,
    3,  3,  3,  3,
    1,  1,  1,  1,
    3,  3,  3,  3,
    4,  4,
    5,  5,
    7,  8,
    8,  4,
    1,  1,  1,  1,
    3,  3,  3,  3,
    1,  1,  1,  1,
    3,  3,  3,  3,
    4,  3,
    6, 10,
    5
  };

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
      // tampilkan baris yang sedang aktif (dari lirikBeat[i] selama durasiLirik[i])
      if (t.inBeat(lirikBeat[i], lirikBeat[i] + durasiLirik[i])) {
        text(lirik[i], width / 2, height - 120);
      }
    }
    hint(ENABLE_DEPTH_TEST);
  }
}

class ElDebug {
  PFont font;        // font untuk teks debug

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