#####################################################################
#  CATATAN UNTUK AI / ORANG YANG MELANJUTKAN PROYEK INI  (BACA DULU) #
#####################################################################
Kalau kamu AI atau developer yang melanjutkan pekerjaan ini:

 1. Baca README_PROYEK.txt dulu (arsitektur + API). File INI (README_PROGRESS.txt)
    berisi status pekerjaan: apa yang sudah jadi, apa yang BELUM DIUJI, dan apa
    yang belum dikerjakan.
 2. Pertahankan arsitektur element: satu fitur visual = satu class El<Nama> di
    file el_<Nama>.pde dengan method show(BeatClock t, ...). Jadwal tampil
    (kapan/beat berapa) HANYA diatur di draw() pada pa_mv.pde.
 3. Semua .pde harus di folder sketch utama (Processing tidak membaca sub-folder).
 4. Element 3D wajib lewat Canvas3D (render offscreen), element 2D wajib
    hint(DISABLE_DEPTH_TEST) + noLights(). Jangan gambar 3D langsung ke layar utama.
 5. JANGAN menganggap kode sudah teruji. Lihat bagian "STATUS PENGUJIAN" di bawah.
 6. Setelah selesai mengerjakan sesuatu, perbarui file ini (bagian CHANGELOG,
    TODO, dan STATUS) supaya estafet berikutnya tetap akurat.

(English summary for AI) Modular Processing P3D music-visual project, beat-synced
via a BeatClock. Elements = classes El*, scheduled in draw() of pa_mv.pde. 3D elements
render through Canvas3D (offscreen PGraphics) to avoid depth conflicts with 2D.
The code was written WITHOUT being compiled/run (no Processing in the authoring
environment) - expect to fix small compile/runtime errors first.

=====================================================================
 1. KONTEKS PROYEK
=====================================================================
- Proyek   : music visual "LOOPING THE ROOM" (Processing, P3D, library processing.sound)
- Lagu     : assets/MainSong.mp3, BPM 162, lirik Jepang (font NotoSansJP-Regular.ttf)
- Acuan visual: video referensi (mp4, ~12 detik) bergaya Backrooms:
    * lorong kuning, karpet, plafon kotak + lampu panel putih, partisi dinding
      kuning, kamera maju terus, karakter anak berlari di tengah
    * teks lirik kinetik (huruf besar melengkung, teks bertumpuk di dinding/lantai)
    * efek VHS/film (grain, bintik debu, garis scan, glitch)
    * kilatan ruangan lain: ruang abu-abu dengan kotak hitam, lorong ungu berpintu
    * bagian akhir: ruang bola (ball pit) dengan perosotan, plafon kotak-kotak ungu
- Pemilik proyek berbahasa Indonesia; komunikasi & komentar kode dalam bahasa Indonesia.

=====================================================================
 2. RIWAYAT PEKERJAAN (CHANGELOG)
=====================================================================
[Tahap 1] Permintaan awal: buat ruangan 3D seperti di video, dalam bentuk FUNGSI yang
          bisa dipanggil saat beat tertentu.
          -> Dibuat BackroomsScene.pde (fungsi drawBackrooms(beatPos, palette) +
             jadwal beat). Sudah DIGANTIKAN tahap 2 (file itu sudah dihapus).

[Tahap 2] Permintaan: ubah total jadi arsitektur "element"; semua tampilan jadi element
          terpisah, tinggal dipanggil manual di draw() sesuai beat. Tanya: apakah
          switch cocok?
          -> Dibuat: core_BeatClock.pde, el_Backrooms, el_Tunnel (Backroom wireframe
             lama), el_Bola, el_Polyrhythm, el_Teks (judul/lirik/debug), el_Kontrol
             (tombol), el__TEMPLATE, pa_mv.pde baru.
          -> Jawaban switch: pakai if(clock.inBeat(a,b)) untuk rentang & overlay;
             switch hanya cocok untuk event sekali di beat tertentu.
          -> Catatan Processing: tidak ada sub-folder untuk .pde, jadi dipakai
             awalan nama file (core_, el_).

[Tahap 3] Laporan: Backrooms 3D "nembus" element 2D.
          -> Dibuat core_Canvas3D.pde; el_Backrooms & el_Tunnel dirender offscreen
             lalu ditempel sebagai gambar. Dibuat README_PROYEK.txt.

[Tahap 4] Dibuat README_PROGRESS.txt (file ini).

[Tahap 5] Permintaan: ubah ElTunnel jadi 4 ruangan Backrooms kamera diam, lebih gelap,
          berdasarkan 4 gambar referensi; nama ElBackroomStatic; ditaruh di bawah class
          ElBackrooms; kemunculan diatur pemilik sendiri.
          -> ElBackroomStatic ditambahkan di bagian bawah el_Backrooms.pde
             (ruang 0 Level 0 gelap, 1 lobi terbengkalai, 2 lorong lengkung hijau,
             3 ruang bermain biru). el_Tunnel.pde DIHAPUS.
          -> pa_mv.pde disesuaikan agar tetap bisa dikompilasi: fallback latar
             sekarang backroomStatic.show(clock, 0). Pemilik akan mengatur sendiri
             kapan tiap ruang muncul.

=====================================================================
 3. STATUS SAAT INI
=====================================================================
SUDAH DIBUAT (kode ada, struktur final):
  [x] BeatClock (beat, subBeat, quarter, eighth, beatPos, frac, newBeat, inBeat,
      atBeat, progress, reset)
  [x] Canvas3D (kanvas 3D offscreen, auto-resize)
  [x] ElBackrooms  (3D, 3 palette: kuning / abu-abu / ungu)
  [x] ElBackroomStatic (3D, 4 ruangan kamera diam; menggantikan ElTunnel yang dihapus)
  [x] ElBola, ElPolyrhythm, ElJudul, ElLirik, ElDebug, ElKontrol (+GUIButton)
  [x] pa_mv.pde dengan jadwal contoh (lihat README_PROYEK.txt bagian 2)
  [x] Dokumentasi: README_PROYEK.txt, el__TEMPLATE.pde

STATUS PENGUJIAN (JUJUR):
  [ ] BELUM pernah dikompilasi / dijalankan di Processing (lingkungan penulis tidak
      punya Processing/javac). Kemungkinan ada error kecil saat run pertama.
  [ ] Perbaikan "3D nembus 2D" lewat Canvas3D BELUM dikonfirmasi berhasil oleh pemilik.
      Penyebabnya adalah dugaan (depth buffer & kamera bersama). Jika masih bermasalah,
      minta screenshot / deskripsi gejala yang tepat sebelum menebak lagi.
  [ ] Performa belum diukur (Backrooms ~12 segmen/frame, + kanvas offscreen
      antialias 4x; jika lambat turunkan: new Canvas3D(2), VIEW, jumlah debu).
  [ ] ElBackroomStatic belum dibandingkan dengan 4 gambar referensi: bentuk perabot,
      warna, dan tingkat gelap (field gelap) masih perkiraan; pemilik perlu menilai dan
      meminta penyesuaian per ruangan.
  [ ] Tampilan Backrooms belum dibandingkan side-by-side dengan video; warna,
      proporsi lorong, kecepatan maju masih perkiraan dari frame video.
  [ ] Perilaku di layar retina / pixelDensity(displayDensity()) untuk kanvas
      offscreen belum diperiksa (bisa terlihat sedikit lebih buram dari layar utama).

FILE LAMA yang harus sudah dihapus dari folder sketch pemilik (jika belum, class
akan bentrok): Background.pde, VisualObject.pde, UI.pde, AudioManager.pde, el_Tunnel.pde.
Konfirmasi pemilik soal ini BELUM ada.

=====================================================================
 4. KEPUTUSAN DESAIN (supaya tidak diperdebatkan ulang)
=====================================================================
- Element = class dengan show(); bukan fungsi global. Alasan: banyak element punya
  state (animasi pulsa, scroll, dsb).
- BeatClock di-update sekali per frame dan dioper ke element; element tidak membaca
  lagu langsung.
- Gerak 3D dihitung dari clock.beatPos (bukan frameCount) -> deterministik, aman saat
  pause/restart/lompat posisi lagu.
- Partisi Backrooms dibuat dengan hash(nomor segmen) -> sama setiap diputar, tanpa
  state acak.
- Latar 3D: tepat satu aktif per frame (rantai if/else-if); element 2D boleh overlap.
- Jadwal beat sengaja ada di draw() main, bukan di dalam element (kecuali ElLirik
  yang datanya melekat pada lirik).
- Jadwal di pa_mv.pde sekarang HANYA CONTOH (Backrooms kuning beat 8-39 & 136-167,
  abu-abu 22-23, ungu 150-151, selain itu ElBackroomStatic ruang 0). Pemilik akan menyesuaikan sendiri.

=====================================================================
 5. TODO / IDE LANJUTAN (belum dikerjakan, urut kira-kira berdasarkan nilai)
=====================================================================
Wajib/awal:
  [ ] Jalankan di Processing, perbaiki error kompilasi/runtime yang muncul.
  [ ] Verifikasi masalah "nembus" benar-benar hilang.
  [ ] Pemilik menyesuaikan jadwal draw() dengan struktur lagu sebenarnya.

Mendekati video referensi (opsional, belum diminta secara eksplisit):
  [ ] ElEfekVHS (2D overlay): grain, bintik debu, garis scan, glitch horizontal,
      vignette. Parameter intensitas bisa mengikuti t.frac / t.newBeat.
  [ ] ElTeksKinetik: lirik/huruf besar melengkung, teks bertumpuk di dinding/lantai
      (di video: tulisan "くりかえす" memenuhi dinding & lantai Backrooms). Bisa
      dibuat sebagai texture di dalam Canvas3D Backrooms (g.text pada bidang 3D).
  [ ] ElRuangBola: ruang bola + perosotan + plafon ungu kotak-kotak (adegan akhir
      "ふらくたる" di video).
  [ ] Variasi ruang untuk ElBackrooms (lorong bergerak): ruang abu-abu dengan kotak
      hitam, lorong ungu dengan pintu (saat ini hanya dibedakan lewat palette warna).
      Catatan: 4 ruang statis dari gambar referensi sudah ada di ElBackroomStatic.
  [ ] Karakter/sprite berlari di tengah (butuh aset gambar; kalau ada spritesheet,
      buat ElKarakter dengan animasi per beat).
  [ ] Transisi antar adegan (flash putih / glitch) memakai t.newBeat atau
      clock.atBeat(n).

Kualitas kode:
  [ ] Pertimbangkan satu Canvas3D bersama untuk semua element 3D jika memori/performa
      jadi masalah (saat ini tiap element 3D punya kanvas sendiri, dibuat lazy).
  [ ] Pindahkan data jadwal ke satu struktur (mis. array jadwal) jika draw() makin
      panjang.

=====================================================================
 6. CARA MELANJUTKAN (CHECKLIST CEPAT)
=====================================================================
  1. Buka folder pa_mv/ di Processing (nama folder = nama main: pa_mv.pde).
  2. Pastikan data/ berisi NotoSansJP-Regular.ttf dan assets/MainSong.mp3
     (path di setup() pa_mv.pde; sesuaikan bila beda).
  3. Pastikan library "Sound" terpasang (Sketch > Import Library > Manage).
  4. Run. Jika ada error, perbaiki dulu sebelum menambah fitur.
  5. Tambah fitur memakai pola di README_PROYEK.txt bagian 4.
  6. Perbarui README_PROGRESS.txt: pindahkan item TODO yang selesai ke CHANGELOG,
     ubah STATUS PENGUJIAN sesuai hasil nyata.

=====================================================================
 7. KONTAK ANTAR-ESTAFET (isi saat ada yang melanjutkan)
=====================================================================
  Terakhir diubah oleh : (isi)
  Tanggal              : (isi)
  Yang dikerjakan      : (isi)
  Yang tertunda        : (isi)
