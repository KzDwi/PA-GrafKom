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
The code was written WITHOUT being compiled/run by the original author. The current
owner HAS run it (Tahap 20) but many edge cases remain untested.

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

[Tahap 6] Perbaikan bug + glitch/teleport anak.
          -> Suara membesar setelah pause->play: play() mereset amp ke 1.0, sekarang lagu.amp(VOLUME) dipanggil ulang.
          -> Pause lalu RESTART cepat = 2 lagu jalan: jump(0) saat pause ikut memutar lagu; diganti stop()+play(), plus debounce klik 200ms dan transitionFx.reset().
          -> BeatClock.atSubBeat(n) ditambahkan. FxTransition.triggerGlitch()/showGlitch() (glitch satu layar, 2 frame).
          -> Glitch di subbeat 142, 158, 174, 191. Anak masuk di subbeat 145, teleport di 158/174/191 (jadwal & posisi: boySub/boyStartX di el_tvstatic.pde).
          -> BELUM dikompilasi/dijalankan (tanpa Processing di lingkungan penulis).

[Tahap 7] Cuplikan pintu loop + adegan kinetik + perbaikan restart.
          -> el_DoorLoop.pde (3D, beat 100-103, loop 2x), fx_crt.pde (layar TV mati/nyala),
             fx_riser.pde (suara naik sintesis), el_Kinetik.pde (adegan beat 103-136, ref video 0:37-0:50;
             slot gambar data/img_kuru.png, img_kurikaesu.png, img_fractal.png, img_slide.png).
          -> el_Kontrol.pde: tombol CHECKPOINT (+ tombol C); RESTART = stop() + jump(checkpoint), langsung play.
          -> el_tvstatic.pde: teleport terakhir anak dihitung mundur agar tiba di tepi kanan di beat 100.
          -> BELUM dikompilasi/dijalankan. Video referensi TIDAK bisa ditonton (tanpa akses internet);
             adegan kinetik dibuat dari deskripsi di README + data lirik.

[Tahap 8] Revisi setelah video referensi (Kurikaesu.mp4) diterima.
          -> el_DoorLoop.pde: pintu terbuka SATU kali (beat 100.3-101.3), kamera maju lalu DIAM.
          -> fx_crt.pde DIHAPUS, diganti fx_mosaic.pde (FxMosaic: transisi kotak-kotak "TV rabun",
             keluar 102.2->103.0, masuk 103.0->103.6).
          -> el_Kinetik.pde DITULIS ULANG mengikuti video: pita spiral zaitun + huruf lirik raksasa,
             1 klon anak berjalan per beat (103->117), kolom emas loncat per beat (mulai 117.5).
             Slot gambar: data/img_walk, img_walk2, img_spiral (png/jpg).

[Tahap 9] Latar terowongan (beat 72-100, ElTvStatic room 4) berganti tiap anak teleport.
          -> el_tvstatic.pde: drawScrollingTape() dipecah jadi drawTunnelBand(t, style) + bandTape/
             bandArch/bandPlay/bandHall. Ukuran band tetap (340px), tetap gelap (overlay room 4).
             style 0 = pita kaset (awal), 1 = lorong lengkung hijau (teleport 1), 2 = ruang bermain
             biru (teleport 2), 3 = lorong berpintu kuning (teleport 3, palet = latar el_DoorLoop).
             Style mengikuti boySub[] lewat boySeg()/tunnelStyle(). Di style 3 scroll melambat & berhenti
             di boyEndBeat, pintu terakhir berhenti di depan anak (sinkron ke adegan pintu).
             Room 3 (beat 56-72) tetap memakai style 0 terang seperti sebelumnya.
          -> BELUM dikompilasi/dijalankan.

[Tahap 10] Adegan "Help Me" (beat 227.5 -> 231).
          -> el_HelpMe.pde (ElHelpMe, 2D overlay): zoom cepat ke pintu (subBeat 455-456, foto layar
             di-zoom 16x dari titik pintu + zoom blur), lalu layar hitam + distorsi putih (garis acak,
             bintik, balok tracking, goresan vertikal, kilap tipis). Teks Base64 "Help Me" (SGVscCBNZQ==)
             muncul 3 subBeat sesudah hitam (subBeat 459 = beat 229.5), huruf menyala satu-satu dari
             distorsi, bergetar & membesar pelan sampai beat 231. Jadwal = konstanta di atas class.
          -> pa_mv.pde: helpMe dideklarasi/dibuat/dipanggil (setelah mosaicFx, sebelum UI); latar 3D
             beat 228-231 dikosongkan; bola & lirik disembunyikan sampai beat 231.
          -> el_LorongCahaya.pde: field sembunyiTeks (lirik disembunyikan mulai beat 227.5).
          -> BELUM dikompilasi/dijalankan. Setelah beat 231 layar jatuh ke latar default (backroomStatic 0).

[Tahap 11] Revisi adegan "Help Me" + pengulangan adegan kinetik.
          -> el_HelpMe.pde: 3-5 huruf Base64 berwarna merah (dipilih acak, diacak ulang tiap subBeat;
             RED_MIN/RED_MAX). Garis distorsi memudar perlahan dari FADE_START=230 sampai hilang di 231
             (pengali am; jumlah & alpha garis turun).
          -> el_Kinetik.pde: show(t, lk, geser) -> semua jadwal/lirik digeser. Beat 231-263 = beat 103-135 + 128.
          -> pa_mv.pde: kinetik.show(clock, lirik, 128) + efekVHS di beat 231-264; mosaik masuk 231.0-231.6
             (dari hitam Help Me); glitch di subBeat 494 & 527 (= 238 & 271 + 256). Bola disembunyikan sampai 264.
          -> BELUM dikompilasi/dijalankan.

[Tahap 12] Redup bertahap di adegan kinetik ke-2 (beat 260-263).
          -> el_Kinetik.pde: field dimMulai/bgMul/colTahap. 4 tahap, 1 per beat (mengikuti loncatan kolom emas):
             1 latar gelap (kolom emas redup), 2 makin gelap, 3 kolom abu-abu, 4 hitam total + karakter saja.
          -> pa_mv.pde setup(): kinetik.dimMulai = 260.  BELUM dikompilasi/dijalankan.

[Tahap 13] Spiral dirapikan + adegan spiral zoom + layar hitam kata akhir.
          -> el_Kinetik.pde: spiral dipusatkan (x = 0.5 lebar), huruf Jepang di atas spiral dimatikan (tampilKana=false).
          -> el_SpiralZoom.pde (beat 264-290): spiral full layar; kamera zoom ke kiri-bawah (264-272), pindah ke
             atas-kanan (272-280), kembali semula (280-290). Konstanta kamera di atas class.
          -> el_KataAkhir.pde (beat 290-297): hitam + distorsi tipis dari atas; lirik beat 292 muncul huruf demi
             huruf (0.4 beat/huruf), jadi merah di beat 296. Mosaik penutup 289-290 di pa_mv.pde.
          -> BELUM dikompilasi/dijalankan.

[Tahap 14] el_SpiralZoom.pde: perpindahan kamera (264, 272, 280) jadi CUT langsung, tanpa animasi zoom/transisi.
          Kamera diam per segmen (DRIFT = 0). BELUM dikompilasi/dijalankan.

[Tahap 15 - revisi: kartu emas kecoklatan transparan, ruangan tetap ganti per beat di 312-328]
          [Tahap 15] Beat 297-328: ruangan 3D per beat + kolom negatif.
          -> el_RuangBeat.pde (ElRuangBeat extends ElBackroomStatic): 16 ruangan (pool, hotel merah, kantor, garasi, sekolah,
             ruang tamu 70-an, ruang bola, gudang, neon, toilet, perpus, kamar anak, aula pilar, lobi lift, ruang putih
             pintu merah, Level 0 kuning besar). Beat 297-311 = ruang 0-14 (1 per beat), beat 312-327 = ruang 15 ditahan + dorong maju pelan.
          -> el_KolomNegatif.pde: kolom 1/4 layar loncat per beat (312-328), warna = negatif latar, alpha rendah (alphaMax=95).
          -> pa_mv.pde: deklarasi/setup, rantai latar 3D, bola disembunyikan sampai 328, mosaik 296.35-297.7.
          -> Tampilan dicek lewat mock + rasterizer (bukan Processing asli); BELUM dijalankan di Processing.

[Tahap 16] Kartu dipertebal (alphaMax 170) + error 328-329 + adegan bingkai blur -> TV.
          -> el_RuangTV.pde (ElRuangTV): beat 329-343 gambar ruangan (ganti per beat, urutan di array urut) di-BLUR dalam bingkai 4:3,
             zoom out pelan sampai seukuran layar TV; 343-344.5 error hitam-putih kotak-kotak lalu TV muncul & menyala; 344.5-... TV tetap
             tayang (isi = ruangan ganti per beat, blur kuat + redup 0.55, latar gelap, cahaya TV mengikuti warna rata-rata ruangan).
          -> el_RuangBeat.pde: field tempel (false = jangan tempel ke layar; hasil diambil lewat cv.pg).
          -> pa_mv.pde: glitch subBeat 656/657/658 (328-329) dan 686/687 (343-343.5); bola hanya tampil beat < 168.
          -> Adegan TV BELUM ada akhirnya (terbuka sampai lagu habis) - atur kalau tahap berikut sudah ditentukan.
          -> Bagian 2D hanya dicek lewat kompilasi + sketsa tata letak, BELUM dijalankan di Processing.

[Tahap 17] Beat 356: TV mati (el_RuangTV.showMati, 0.8 beat): layar redup dari pinggir ke tengah + menipis jadi garis,
          kilau memanjang + bintang putih, cahaya TV menggelap sampai HITAM PENUH di beat 357 (tinggal judul LOOPING THE ROOM).
          Konstanta OFF_MULAI / OFF_DUR di el_RuangTV.pde. Setelah 357 ElRuangTV tidak menggambar apa-apa.
          BELUM dijalankan di Processing.

[Tahap 18] MAIN MENU (el_MainMenu.pde) - Backrooms 3D + Terminal UI
          -> Menu baru muncul di awal sebelum lagu diputar, jadi "gerbang" sebelum game.
          -> Latar 3D: lorong Backrooms kamera maju pelan (camZ = -t*28), parallax mouse halus
             (mx, my = lerp ke posisi mouse ternormalisasi, faktor 0.035).
          -> UI terminal kiri atas: judul "LOOPING THE ROOM", status SIGNAL DETECTED (pulse),
             tombol ENTER THE ROOM, slider AUDIO OUTPUT (drag), footer "ESCAPE IS NOT GUARANTEED".
          -> Fade-in 1.6 detik saat muncul, fade-out 0.85 detik saat PLAY ditekan.
          -> menu.selesai = true setelah fade-out; draw() utama memanggil mulaiLagu() sekali.
          -> Input: klik tombol, drag slider. mousePressed/mouseDragged/mouseReleased diteruskan
             dari sketch utama (kalau !menu.selesai).
          -> v3 fix: lightF range 0.72..1.10 dengan smootherstep, detailLampu digambar di 
             CEIL+1.2 (frame) & CEIL+2.0 (permukaan), garis vertikal wallpaper di-snap ke grid 
             world 125u (bukan camera-relative), stripWall 6-band dengan pseudo-AO vertikal.
          -> BELUM dikompilasi oleh penulis; pemilik sudah menjalankan: OK.

[Tahap 19] HD Backrooms (ElBackrooms + ElBackroomStatic) - per-vertex lighting
          -> ElBackrooms (perubahan besar dari versi awal):
             * lit(): ambient + 6 lampu terdekat (diffuse dengan wrap lighting + Blinn-Phong
               spekular untuk lantai) + AO palsu di sudut + tone-map + fog. Setiap vertex
               dihitung sendiri (bukan 1 warna per quad).
             * Halo additive di sekitar tiap lampu (pass kedua, setelah benda solid,
               blendMode ADD, hint DISABLE_DEPTH_MASK).
             * Lampu rusak berkedip: 15% lampu punya gain 0.2/1.0 bergantung pada
               sin(beatT * 19) * sin(beatT * 5.3).
             * Vignette.
             * Detail: sambungan karpet, garis kotak plafon, plint, wainscot, crown,
               rel dinding (wallTrim), stripesZ/stripesX dengan lineL (lighting per segmen).
             * Pantulan glossy di lantai (gloss = 0.55), camera position dihitung untuk
               vektor view.
          -> ElBackroomStatic:
             * Detail baru: trim (plint + crown), wainscot (panel bawah dinding), gridH
               (ubin plafon + ubin lantai), contactShadows (gradien gelap di pertemuan
               dinding/lantai/plafon), recessed (lampu plafon bulat), panel (dengan
               glow), vent (ventilasi), stain (noda lantai), ball (bola mainan +
               highlight), sconce (lampu dinding di lorong lengkung), archTrim.
             * Field baru: debu (int, jumlah partikel dust).
             * addGlow / glows: glow additive di akhir.
          -> ⚠ BUG: OOM runtime (OpenGL 1285 + Chunk::new malloc failure) karena 
             draw call meledak (ribuan lit() per frame, ~864.000 alokasi color per 
             detik, JIT stress).

[Tahap 20] Tuning performa + integrasi menu + ESC ke menu
          -> OOM fix (belum terbukti hilang total, tergantung hardware):
             * quadL nu×nv: floor 10×5 -> 8×4, ceiling 10×5 -> 6×3, wall 5×3 -> 3×2,
               block 5×3 -> 3×2.
             * lineL seg: 4 -> 3 (floor seam), 4 -> 2 (grid plafon).
             * stripesZ/stripesX seg: 4 -> 1.
             * prismSub trim: 18 -> 6.
             * dust: 6 (di cell) tetap, ElBackroomStatic.debu default 50 -> 0.
             * halo: mulai dari k0+1 (skip yang di belakang kamera).
          -> Rekomendasi tuning tambahan (belum diimplementasi): pixelDensity(1),
             flag `hd` di ElBackrooms untuk matikan detail di scene tertentu, 
             gloss = 0 kalau masih OOM.
          -> pa_mv.pde: draw() dibuka dengan cek menu:
                if (!menu.selesai) {
                  VOLUME = menu.volume;
                  menu.show();
                  if (menu.selesai) mulaiLagu();
                  return;
                }
             mousePressed/Dragged/Released menu-aware.
             keyPressed: ENTER/RETURN/SPASI pemicu menu.tekanPlay() saat !menu.selesai.
          -> mulaiLagu(): lagu.stop() + jump(0) + loop() + amp(VOLUME). Tidak ada cek
             !isPlaying() supaya restart selalu dari awal (mencegah "lanjut dari posisi 
             sebelumnya" kalau user kembali ke menu setelah main sebentar).
          -> ESC untuk kembali ke menu (el_Kontrol.kembaliKeMenu):
             * lagu.stop() — TIDAK jump(0), karena jump() pada SoundFile yang stopped
               akan MEMUTAR lagu dari posisi itu.
             * clock.reset(), transitionFx.reset(), riser.stopNow(), setPlaying(true).
             * menu.reset(): selesai=false, memudar=false, tMulai=now, hPlay=0, hVol=0.
             * keyPressed: if (key == ESC) { key = 0; if (menu.selesai) { kembaliKeMenu(); 
               menu.reset(); } }
          -> Bug fix dari tahap sebelumnya: kembali ke menu malah memutar lagu (karena 
             jump(0) pada stopped = play), dan masuk lagi malah lanjut (karena mulaiLagu
             cek !isPlaying()). Keduanya sudah ditangani.
          -> BELUM dikompilasi oleh penulis; pemilik sudah jalankan dan laporkan "sudah OK".

[Tahap 21] Animasi lima clone pada ElSpiralZoom (T0-T3).
          -> el_SpiralZoom.pde: lima gambar pose1.png, pose2.png, pose3.png, pose4f.png,
             pose5.png dimuat dari assets/. pose4f.png menggantikan pose4.png untuk slot ke-4.
          -> Lima clone berputar satu posisi setiap beat dan bergerak cepat ke kiri selama
             0.3 beat; clone yang keluar muncul kembali dari kanan.
          -> Baris aktif di rentang T0-T1, T1-T2, dan T2-T3; urutan rotasi dimulai ulang
             saat memasuki setiap rentang.
          -> Posisi vertikal centerY saat ini: T0=0, T1=0.85, T2=0.5. Tinggi gambar:
             T0/T1=1.5 kali tinggi kanvas, T2=0.8 kali tinggi kanvas. T2 memakai jarak
             posisi merata sepanjang lebar kanvas serta penyesuaian ukuran berdasarkan
             lebar jarak clone; hasil visual/ada tidaknya tumpang tindih BELUM diverifikasi.
          -> BELUM dikompilasi atau dijalankan di Processing.

=====================================================================
 3. STATUS SAAT INI
=====================================================================
SUDAH DIBUAT (kode ada, struktur final):
  [x] BeatClock (beat, subBeat, quarter, eighth, beatPos, frac, newBeat, inBeat,
      atBeat, atSubBeat, progress, reset)
  [x] Canvas3D (kanvas 3D offscreen, auto-resize)
  [x] ElMainMenu (menu awal: Backrooms 3D + terminal UI + volume + play)
  [x] ElBackrooms  (3D, 3 palette: kuning / abu-abu / ungu, lighting per-vertex)
  [x] ElBackroomStatic (3D, 4 ruangan kamera diam + detail baru)
  [x] ElBola, ElPolyrhythm, ElJudul, ElLirik, ElDebug, ElKontrol (+GUIButton,
      termasuk kembaliKeMenu)
  [x] ElSpiralZoom dengan lima clone berotasi per beat pada segmen T0-T3
  [x] pa_mv.pde dengan menu gate + jadwal beat + mulaiLagu + ESC ke menu
  [x] Dokumentasi: README_PROYEK.txt, el__TEMPLATE.pde

STATUS PENGUJIAN (JUJUR):
  [x] Menu muncul, PLAY masuk ke game, ESC kembali ke menu: DIJALANKAN oleh pemilik.
  [x] Lagu play/restart dari 0 setiap kali masuk game: DIJALANKAN oleh pemilik.
  [~] ElBackrooms HD: OOM dilaporkan di Tahap 19. Setelah tuning Tahap 20
      (quadL diturunkan, lineL seg dikurangi) BELUM dikonfirmasi oleh pemilik
      apakah masih OOM atau tidak.
  [~] ElMainMenu: setelah v3 fix (lightF, detailLampu, wallpaper world-fixed)
      dilaporkan OK oleh pemilik.
  [ ] Performa ElBackrooms HD belum diukur resmi (60 fps? 30 fps? stutter?).
      Jika masih berat: turunkan lagi nu×nv, matikan gloss, pixelDensity(1),
      atau tambahkan flag `hd`.
  [ ] Masalah "3D nembus 2D" lewat Canvas3D BELUM dikonfirmasi ulang oleh pemilik
      setelah ElBackrooms HD. Jika masih bermasalah, minta screenshot.
  [ ] ElBackroomStatic belum dibandingkan dengan 4 gambar referensi.
  [ ] ElMainMenu belum dibandingkan side-by-side dengan referensi visual (video).
  [ ] Perilaku di layar retina / pixelDensity(displayDensity()) untuk kanvas
      offscreen belum diperiksa (bisa terlihat sedikit lebih buram dari layar utama
      dan bisa jadi penyebab utama OOM di layar HiDPI).
  [ ] Adegan kinetik, pintu, mosaic, TV, Help Me, kata akhir, ruang beat:
      dibuat oleh penulis tanpa Processing. Beberapa dilaporkan sudah OK oleh
      pemilik, sebagian BELUM diverifikasi.

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
- Menu = state terpisah (menu.selesai). draw() langsung return kalau !menu.selesai,
  jadi scene game tidak di-update selama di menu (clock tidak jalan, lagu tidak
  play). Volume slider menu mengubah VOLUME global di setiap frame menu terbuka.
- Restart / masuk game selalu mulai dari lagu posisi 0 (bukan cek isPlaying()).
  Ini mencegah bug "lanjut dari posisi sebelumnya" setelah user bolak-balik menu.
- ESC di Processing default = quit sketch. Harus `key = 0;` untuk cegah, baru
  tangani sendiri.

=====================================================================
 5. TODO / IDE LANJUTAN (belum dikerjakan, urut kira-kira berdasarkan nilai)
=====================================================================
Wajib/awal:
  [ ] Verifikasi apakah OOM setelah Tahap 20 sudah hilang. Kalau belum:
      * pixelDensity(1) di setup().
      * Tambahkan flag `hd` di ElBackrooms, default false. Kalau true: aktifkan
        wallTrim/stripesZ/detail. Kalau false: cuma quadL dasar + lampu.
      * Matikan gloss (gloss = 0) kalau spekular masih berat.
      * Naikkan heap JVM ke 2048 MB di Processing Preferences.
  [ ] Verifikasi masalah "nembus" benar-benar hilang (dengan HD lighting yang
      lebih banyak draw call).
  [ ] Pemilik menyesuaikan jadwal draw() dengan struktur lagu sebenarnya.

Mendekati video referensi (opsional, belum diminta secara eksplisit):
  [ ] ElEfekVHS (2D overlay): grain, bintik debu, garis scan, glitch horizontal,
      vignette. (Sebagian sudah ada di el_EfekVHS.pde, tapi mungkin bisa dipertebal.)
  [ ] ElTeksKinetik (di dalam 3D): lirik/huruf besar melengkung, teks bertumpuk di
      dinding/lantai (di video: tulisan "くりかえす" memenuhi dinding & lantai
      Backrooms). Bisa dibuat sebagai texture di dalam Canvas3D Backrooms.
  [ ] ElRuangBola: ruang bola + perosotan + plafon ungu kotak-kotak.
  [ ] Variasi ruang untuk ElBackrooms (lorong bergerak): ruang abu-abu dengan kotak
      hitam, lorong ungu dengan pintu. Saat ini hanya dibedakan lewat palette warna.
  [ ] Karakter/sprite berlari di tengah (butuh aset gambar; kalau ada spritesheet,
      buat ElKarakter dengan animasi per beat).
  [ ] Transisi antar adegan (flash putih / glitch) memakai t.newBeat atau
      clock.atBeat(n).
  [ ] Latar menu: bisa dikasih tambahan partikel debu 3D atau sfx halus (bukan
      lagu utama) - opsional.

Kualitas kode:
  [ ] Pertimbangkan satu Canvas3D bersama untuk semua element 3D jika memori/performa
      jadi masalah (saat ini tiap element 3D punya kanvas sendiri, dibuat lazy:
      ElBackrooms, ElBackroomStatic, ElDoorLoop, ElVoidFall, ElLorongCahaya,
      ElRuangBeat (extends ElBackroomStatic - punya cv sendiri), ElRuangTV,
      ElMainMenu. Itu banyak framebuffer GPU).
  [ ] Pindahkan data jadwal ke satu struktur (mis. array jadwal) jika draw() makin
      panjang.
  [ ] Kalau ElRuangBeat extends ElBackroomStatic, lebih baik berbagi Canvas3D
      lewat parameter (bukan bikin field cv sendiri) supaya hemat framebuffer.

=====================================================================
 6. CARA MELANJUTKAN (CHECKLIST CEPAT)
=====================================================================
  1. Buka folder pa_mv/ di Processing (nama folder = nama main: pa_mv.pde).
  2. Pastikan data/ berisi NotoSansJP-Regular.ttf dan assets/MainSong.mp3
     (path di setup() pa_mv.pde; sesuaikan bila beda).
  3. Pastikan library "Sound" terpasang (Sketch > Import Library > Manage).
  4. Kalau OOM: Preferences > Increase maximum available memory > 2048 MB.
     Kalau masih OOM: ganti pixelDensity(displayDensity()) -> pixelDensity(1).
  5. Run. Kalau ada error, perbaiki dulu sebelum menambah fitur.
  6. Tambah fitur memakai pola di README_PROYEK.txt bagian 4.
  7. Perbarui README_PROGRESS.txt: pindahkan item TODO yang selesai ke CHANGELOG,
     ubah STATUS PENGUJIAN sesuai hasil nyata.

=====================================================================
 7. KONTAK ANTAR-ESTAFET (isi saat ada yang melanjutkan)
=====================================================================
  Terakhir diubah oleh : (isi)
  Tanggal              : (isi)
  Yang dikerjakan      : (isi)
  Yang tertunda        : (isi)