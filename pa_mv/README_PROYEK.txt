=====================================================================
 DOKUMENTASI PROYEK: "LOOPING THE ROOM" - MUSIC VISUAL (Processing P3D)
 File ini juga dirancang untuk ditempel ke AI lain sebagai konteks.
=====================================================================

---------------------------------------------------------------------
 0. RINGKASAN SINGKAT (untuk AI)
---------------------------------------------------------------------
- Bahasa/Platform : Processing (Java mode), renderer P3D, library processing.sound.
- Tujuan          : video musik interaktif yang visualnya disinkronkan ke beat lagu
                    (lagu: assets/MainSong.mp3, BPM 162).
- Arsitektur      : modular. Setiap hal yang tampil = satu "ELEMENT" (class berawalan El)
                    dengan satu method utama show(...). File utama (pa_mv.pde) hanya
                    memutuskan KAPAN (beat berapa) tiap element dipanggil.
- Satu jam beat   : objek BeatClock di-update 1x per frame, lalu dikirim ke semua element.
- Dua jenis element:
    * 3D (latar)  -> dirender ke kanvas offscreen (Canvas3D) lalu ditempel sebagai gambar.
    * 2D (overlay)-> digambar langsung ke layar, depth test dimatikan.
- Batasan Processing: semua file .pde HARUS ada di folder sketch utama (sub-folder
  tidak dikompilasi). Karena itu pengelompokan memakai awalan nama file:
    core_*.pde = inti/sistem,  el_*.pde = element visual.
- Nama folder sketch harus sama dengan nama file main (folder pa_mv/ -> pa_mv.pde).

---------------------------------------------------------------------
 1. STRUKTUR FILE
---------------------------------------------------------------------
pa_mv/
  pa_mv.pde             MAIN: setup element + JADWAL pemanggilan di draw() + mousePressed
  core_BeatClock.pde    class BeatClock   (jam beat)
  core_Canvas3D.pde     class Canvas3D    (kanvas 3D offscreen, mencegah 3D "nembus" 2D)
  el_Backrooms.pde      class ElBackrooms (3D) lorong Backrooms kamera bergerak
                        + class ElBackroomStatic (3D) 4 ruangan kamera DIAM
                        (el_Backrooms.pde juga memuat class ElBackroomStatic: 4 ruangan kamera diam)
  el_Bola.pde           class ElBola      (2D) bentuk di tengah layar, berdenyut tiap beat
  el_Polyrhythm.pde     class ElPolyrhythm(2D) indikator 4 layer ritme, kanan atas
  el_Teks.pde           class ElJudul, ElLirik, ElDebug (2D teks)
  el_Kontrol.pde        class ElKontrol + GUIButton (2D tombol Play/Pause & Restart)
  el__TEMPLATE.pde      kerangka element baru (semua di-comment)
  README_PROYEK.txt     file ini
  data/                 (dibuat manual) NotoSansJP-Regular.ttf, assets/MainSong.mp3
                        -> cek path di setup() jika dipindah

File lama yang SUDAH TIDAK DIPAKAI dan harus dihapus bila masih ada:
  Background.pde, VisualObject.pde, UI.pde, AudioManager.pde
  (isinya sudah dipindah ke el_Bola, el_Polyrhythm/el_Kontrol, core_BeatClock;
   tunnel wireframe lama DIHAPUS, digantikan ElBackroomStatic)
  el_Tunnel.pde juga sudah dihapus - hapus bila masih ada di folder sketchmu.

---------------------------------------------------------------------
 2. ALUR FRAME (pa_mv.pde -> draw())
---------------------------------------------------------------------
  1. clock.update(lagu.position() * 1000)    // hitung beat dari posisi lagu (ms)
  2. background(0)
  3. LATAR 3D  : tepat satu element 3D digambar (if / else if berdasarkan beat)
  4. ELEMENT 2D: bola, polyrhythm, judul, lirik  (urutan panggil = urutan tumpukan)
  5. UI        : kontrol (tombol), debug (teks beat)
  6. (opsional) blok switch untuk event sekali jalan

Contoh jadwal yang aktif sekarang (UBAH sesuka hati):
  beat 22-23           -> Backrooms palette 1 (abu-abu)
  beat 150-151         -> Backrooms palette 2 (ungu)
  beat 8-39, 136-167   -> Backrooms palette 0 (kuning)
  selain itu           -> ElBackroomStatic ruang 0 (default; ganti sesuai keinginan)
  bola                 -> selalu
  polyrhythm           -> beat 0-199
  judul, lirik         -> selalu (lirik punya timing sendiri di el_Teks.pde)

ATURAN PENTING:
- Pada rantai if/else-if latar 3D, rentang yang paling SEMPIT taruh paling atas.
- Latar 3D memanggil background sendiri, jadi cukup satu yang aktif per frame.
- Element 2D boleh tampil bersamaan; yang dipanggil terakhir muncul paling depan.
- Hentikan/ jeda lagu otomatis membekukan visual, karena semua gerakan 3D dihitung dari
  clock.beatPos (bukan dari frameCount/millis).

---------------------------------------------------------------------
 3. API
---------------------------------------------------------------------
3.1 BeatClock  (core_BeatClock.pde)      instance global: clock
  Field (read-only dari sisi element):
    float bpm            = 162
    float beatDuration   ms per beat
    float posMs          posisi lagu dalam ms
    float beatPos        posisi lagu dalam beat, pecahan (mis. 12.37)
    float frac           0..1, progres di dalam beat sekarang
    int   beat           beat sekarang (bulat)
    int   subBeat        hitungan 1/2 beat
    int   quarterBeat    hitungan 1/4 beat
    int   eighthBeat     hitungan 1/8 beat
    boolean newBeat      true HANYA di frame pertama beat baru
  Method:
    void    update(float posMs)        dipanggil sekali per frame oleh main
    void    reset()                    dipanggil saat restart lagu
    boolean inBeat(int dari, int sampai)  true jika dari <= beat < sampai
    boolean atBeat(int n)              true sekali saat beat n baru mulai
    float   progress(int dari, int sampai) 0..1 progres di dalam rentang beat

3.2 Canvas3D  (core_Canvas3D.pde)
    PGraphics begin()   siapkan kanvas offscreen P3D (otomatis dibuat ulang saat
                        window di-resize), mulai menggambar, return PGraphics "g"
    void end()          selesai gambar, lalu tempel ke layar sebagai gambar 2D
                        (depth test dimatikan saat menempel)
  Alasan ada: 3D yang digambar langsung ke layar memakai depth buffer, kamera, dan
  lampu yang sama dengan 2D, sehingga dinding 3D bisa menutupi/menembus element 2D.
  Dengan kanvas offscreen, 3D hanya "gambar latar" biasa.

3.3 ElBackrooms (3D)   new ElBackrooms();   show(BeatClock t, int palette)
    palette: 0 kuning (default), 1 abu-abu, 2 ungu
    Isi: lantai karpet, plafon kotak + lampu panel zig-zag, dinding luar bergaris
    wallpaper, partisi acak (kiri / kanan / melintang), debu melayang, kabut jarak.
    Gerak kamera: maju sesuai beatPos (UNITS_PER_BEAT), goyang kiri-kanan tiap 4 beat,
    naik-turun tiap beat, hentakan FOV + roll tiap beat.
    Pengaturan (konstanta di atas class): CELL, HALF, FLOOR, CEIL, VIEW, UNITS_PER_BEAT.
    Partisi bersifat deterministik (hash dari nomor segmen) -> sama setiap kali diputar.

3.4 ElBackroomStatic (3D)   new ElBackroomStatic();   show(BeatClock t, int ruang)
    (class ada di bagian bawah el_Backrooms.pde, menggantikan ElTunnel)
    4 ruangan dengan KAMERA DIAM, sengaja gelap + vignette, berdasarkan 4 gambar referensi:
      ruang 0 = Level 0 gelap   (wallpaper kuning-hijau, pilar, 1 lampu panel, pintu gelap)
      ruang 1 = Lobi terbengkalai (kursi mustard, sofa merah, karpet pink, kolom, puing,
                                   mural hutan oranye di belakang)
      ruang 2 = Lorong lengkung hijau (5 portal lengkung berurutan, lantai hijau)
      ruang 3 = Ruang bermain biru (alcove lengkung dengan balok mainan, jendela bulat
                                    kuning & pink, karpet pink + lingkaran kuning)
    Nilai ruang di luar 0..3 di-wrap (mis. 5 -> 1, -1 -> 3).
    Field opsional:  gelap (kecerahan global, default 0.7)  |  kedip (denyut lampu
    per beat, default 0 = mati).
    Cara kerja pencahayaan: lampu titik berwarna, dihitung PER-VERTEX (quad dipecah
    kecil-kecil) + kabut gelap makin jauh. Benda dibuat dari prism/cyl/ring/disc/archWall.
    Mengubah isi ruangan = edit method roomLevel0/roomLobi/roomArch/roomPlay.

3.5 ElBola (2D)        new ElBola(float baseSize);   show(BeatClock t)
    Membesar tiap newBeat lalu mengecil. Bentuk berganti per beat (beat % 4):
    0 lingkaran, 1 persegi, 2 segitiga, 3 belah ketupat. Selalu di tengah layar.

3.6 ElPolyrhythm (2D)  new ElPolyrhythm(float w, float h);   show(BeatClock t)
    Kotak di kanan atas: 4 layer (1/1 bola merah, 1/2 kotak cyan, 1/4 garis hijau,
    1/8 partikel magenta) yang berkedip tiap hitungannya.

3.7 ElJudul / ElLirik / ElDebug (2D teks)   (file el_Teks.pde)
    new ElJudul(PFont, String isi);  new ElLirik(PFont);  new ElDebug(PFont);
    show(BeatClock t) pada ketiganya.
    Data lirik ada di ElLirik: array lirik[], lirikBeat[] (beat mulai), durasiLirik[]
    (lama tampil dalam beat). Tambah baris lirik = tambah ke ketiga array dengan urutan sama.

3.8 ElKontrol (2D)     new ElKontrol(SoundFile lagu, BeatClock clock)
    show()              gambar tombol PLAY/PAUSE dan RESTART (kiri atas)
    mousePressed()      HARUS dipanggil dari void mousePressed() di main
    Restart: lagu.jump(0) + clock.reset().

---------------------------------------------------------------------
 4. CARA MENAMBAH ELEMENT BARU
---------------------------------------------------------------------
Contoh: element "Hujan" muncul di beat 32-47.

  a) Buat file baru el_Hujan.pde (salin dari el__TEMPLATE.pde):

     class ElHujan {
       ElHujan() { }
       void show(BeatClock t) {
         hint(DISABLE_DEPTH_TEST);   // 2D wajib
         noLights();
         // ... gambar ...
         hint(ENABLE_DEPTH_TEST);
       }
     }

  b) pa_mv.pde, bagian deklarasi :  ElHujan hujan;
  c) pa_mv.pde, setup()           :  hujan = new ElHujan();
  d) pa_mv.pde, draw()            :  if (clock.inBeat(32, 48)) hujan.show(clock);

Untuk element 3D baru, pakai pola Canvas3D (contoh lengkap: ElBackroomStatic di el_Backrooms.pde):

     class ElLaut {
       Canvas3D cv = new Canvas3D();
       void show(BeatClock t) {
         PGraphics g = cv.begin();
         g.background(0);
         g.lights();
         // semua gambar pakai "g." -> g.box(), g.translate(), g.fill(), dst
         cv.end();
       }
     }
  Panggil di bagian LATAR 3D (rantai if/else-if) di draw().

Konvensi:
- Nama class berawalan "El", nama file berawalan "el_".
- Satu method utama show(BeatClock t, ...parameter opsional...).
- State internal (animasi, timer) disimpan sebagai field class, bukan variabel global.
- Element tidak boleh memutuskan kapan dirinya tampil; itu tugas draw() di main.
  (Pengecualian: ElLirik, karena data waktunya melekat pada lirik.)
- Element 2D selalu: hint(DISABLE_DEPTH_TEST) + noLights() di awal,
  hint(ENABLE_DEPTH_TEST) di akhir.

---------------------------------------------------------------------
 5. SWITCH ATAU IF?
---------------------------------------------------------------------
- Tampilkan element pada RENTANG beat  -> if (clock.inBeat(a, b)).
  switch tidak bisa rentang (hanya nilai persis) dan hanya satu case yang jalan,
  sehingga tidak cocok untuk element yang harus tampil bersamaan.
- Event SEKALI di beat tertentu (flash, ganti state, trigger) -> switch cocok:

    if (clock.newBeat) {
      switch (clock.beat) {
        case 64: /* sekali di beat 64 */ break;
        case 96: /* sekali di beat 96 */ break;
      }
    }
  atau satu event:  if (clock.atBeat(64)) { ... }

---------------------------------------------------------------------
 6. CATATAN TEKNIS & MASALAH YANG PERNAH MUNCUL
---------------------------------------------------------------------
- "3D nembus 2D": penyebab = depth buffer & kamera dipakai bersama. Solusi yang dipakai:
  Canvas3D (render 3D offscreen). Jika masih ada masalah visual, cek apakah ada
  element 2D yang lupa hint(DISABLE_DEPTH_TEST) atau memanggil kamera/perspective sendiri.
- Window bisa di-resize: element 2D memakai width/height tiap frame; Canvas3D membuat
  ulang kanvas saat ukuran berubah.
- Performa: Backrooms menggambar ~12 segmen per frame dengan quad + garis. Jika berat,
  kecilkan VIEW, kurangi jumlah debu (loop i < 6 di cell()), atau turunkan
  antialias Canvas3D (new Canvas3D(2)).
- ElBackroomStatic: performa tergantung jumlah quad per ruangan (lantai 14x14, dinding,
  furnitur). Jika berat: kurangi angka pecahan di shell(), atau new Canvas3D(2).
  Tampilan dirancang untuk window potret 720x900 (FOV vertikal 62 derajat).
- Lagu ber-pause: lagu.position() berhenti -> beatPos berhenti -> semua visual diam.
- Font Jepang: createFont("NotoSansJP-Regular.ttf", 32) -> file harus ada di folder data/.

---------------------------------------------------------------------
 7. TEMPLATE PROMPT UNTUK AI LAIN
---------------------------------------------------------------------
Tempel bagian 0-5 file ini + lampirkan file .pde terkait, lalu gunakan:

  "Ini proyek Processing P3D music visual dengan arsitektur element (lihat dokumentasi).
   Buatkan element baru bernama El<Nama> dalam file el_<Nama>.pde yang:
   - punya method show(BeatClock t, ...)
   - tipe: [2D | 3D (pakai Canvas3D)]
   - tampilannya: [deskripsi visual]
   - bereaksi terhadap beat lewat t.newBeat / t.frac / t.beat
   Beri juga 3 baris yang harus ditambah ke pa_mv.pde (deklarasi, setup, draw) beserta
   contoh rentang beatnya. Jangan ubah file lain kecuali perlu."

Untuk meminta perubahan jadwal:
  "Atur draw() di pa_mv.pde agar: Backrooms kuning di beat A-B, abu-abu di C-D, ..."
