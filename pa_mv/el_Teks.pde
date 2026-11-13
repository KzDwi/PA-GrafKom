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
  PFont fontZpix;    // font khusus beat 72-99

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

    "ああ","ああ、扉を開け","意味も忘れ",
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
    264, 266, 269,
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
    6,  6,
    5,  5,
    7,  8,
    8,  4,
    1,  1,  1,  1,
    3,  3,  3,  3,
    1,  1,  1,  1,
    3,  3,  3,  3,
    2,  3,  5,
    6, 10,
    4
  };

  ElLirik(PFont font) {
    this.font = font;
    this.fontZpix = createFont("zpix.ttf", 32);
  }

  void show(BeatClock t) {
    hint(DISABLE_DEPTH_TEST);
    noLights();
    textFont(t.beat >= 72 && t.beat < 100 ? fontZpix : font);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(30);
    for (int i = 0; i < lirik.length; i++) {
      // tampilkan baris yang sedang aktif (dari lirikBeat[i] selama durasiLirik[i])
      if (t.inBeat(lirikBeat[i], lirikBeat[i] + durasiLirik[i])) {
        float alpha = lyricAlpha(lirik[i], t.beatPos);
        if (alpha <= 0) continue;
        fill(255, alpha);
        float shake = lyricShake(t.beat);
        if (shake > 0) drawShakyLine(lirik[i], width / 2, height - 120, shake, t.beatPos);
        else if (lirik[i].equals("終わらないロード") && t.beatPos >= 180) {
          drawWideDashLine(lirik[i], width / 2, height - 120, t.beatPos);
        } else if (lirikBeat[i] >= 264 && lirikBeat[i] <= 281 &&
                   t.beatPos < lirikBeat[i] + 0.5) {
          drawSlidingLyric(i, t.beatPos, alpha);
        } else text(lirik[i], width / 2, height - 120);
      }
    }
    hint(ENABLE_DEPTH_TEST);
  }

  float lyricAlpha(String line, float beatPos) {
    float fadeStart;
    if (line.equals("空回るソウト")) fadeStart = 173;
    else if (line.equals("どこまでも続いてく")) fadeStart = 288;
    else return 255;
    if (beatPos < fadeStart) return 255;
    int fadeStep = (int) floor(beatPos * 1.2) - (int) floor(fadeStart * 1.2);
    float fadeProgress = constrain(fadeStep / 5.0, 0, 1);
    return 255 * (1 - fadeProgress);
  }

  void drawSlidingLyric(int index, float beatPos, float alpha) {
    float start = lirikBeat[index];
    float progress = constrain((beatPos - start) / 0.5, 0, 1);
    float slideDistance = width * 0.25;
    float centerY = height - 120;
    if (progress < 1 && index > 0 &&
        lirikBeat[index - 1] + durasiLirik[index - 1] == lirikBeat[index]) {
      fill(255);
      text(lirik[index - 1], width / 2 - slideDistance * progress, centerY);
    }
    fill(255, alpha);
    text(lirik[index], width / 2 + slideDistance * (1 - progress), centerY);
  }

  float lyricShake(int beat) {
    if (beat >= 104 && beat < 111 || beat >= 120 && beat < 126) return 2;
    if (beat >= 111 && beat < 114 || beat >= 127 && beat < 130) return 5;
    if (beat >= 114 && beat < 117 || beat >= 131 && beat < 134) return 10;
    if (beat >= 117 && beat < 120 || beat >= 135 && beat < 138) return 20;

    if (beat >= 232 && beat < 238 || beat >= 248 && beat < 254) return 2;
    if (beat >= 239 && beat < 241 || beat >= 255 && beat < 257) return 5;
    if (beat >= 242 && beat < 244 || beat >= 258 && beat < 260) return 10;
    if (beat >= 245 && beat < 247 || beat >= 261 && beat < 263) return 20;

    
    if (beat >= 292 && beat < 296) return 2;
    return 0;
  }

  void drawShakyLine(String line, float centerX, float y, float amount, float beatPos) {
    pushStyle();
    textAlign(LEFT, CENTER);
    float x = centerX - textWidth(line) / 2;
    int shakeStep = (int) floor(beatPos * 1.5);
    for (int i = 0; i < line.length(); i++) {
      String letter = line.substring(i, i + 1);
      float dx = randomLetterOffset(shakeStep, i, 0, amount);
      float dy = randomLetterOffset(shakeStep, i, 1, amount);
      text(letter, x + dx, y + dy);
      x += textWidth(letter);
    }
    popStyle();
  }

  void drawWideDashLine(String line, float centerX, float y, float beatPos) {
    float dashScale = lerp(1, 2.5, constrain(beatPos - 180, 0, 1));
    pushStyle();
    textAlign(LEFT, CENTER);
    float totalWidth = 0;
    for (int i = 0; i < line.length(); i++) {
      String letter = line.substring(i, i + 1);
      float scaleX = letter.equals("ー") ? dashScale : 1;
      totalWidth += textWidth(letter) * scaleX;
    }

    float x = centerX - totalWidth / 2;
    for (int i = 0; i < line.length(); i++) {
      String letter = line.substring(i, i + 1);
      float letterWidth = textWidth(letter);
      if (letter.equals("ー")) {
        pushMatrix();
        translate(x, y);
        scale(dashScale, 1);
        text(letter, 0, 0);
        popMatrix();
      } else {
        text(letter, x, y);
      }
      x += letterWidth * (letter.equals("ー") ? dashScale : 1);
    }
    popStyle();
  }

  float randomLetterOffset(int step, int letterIndex, int axis, float amount) {
    int hash = step * 73856093 ^ letterIndex * 19349663 ^ axis * 83492791;
    hash = (hash ^ (hash >>> 13)) * 1274126177;
    hash ^= hash >>> 16;
    float value = (hash & 0x7fffffff) / 2147483647.0;
    return (value * 2 - 1) * amount;
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