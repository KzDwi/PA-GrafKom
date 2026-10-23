// =====================================================================
//  TEMPLATE ELEMENT BARU  (semua baris di-comment, aman dibiarkan)
//  Salin ke file baru, mis. el_Hujan.pde, lalu hapus tanda //
//
// class ElHujan {
//   // state/variabel milik element ini
//
//   ElHujan() { }                       // dibuat sekali di setup()
//
//   void show(BeatClock t) {            // dipanggil di draw() saat ingin tampil
//     // 2D  -> awali dengan hint(DISABLE_DEPTH_TEST); noLights();  akhiri hint(ENABLE_DEPTH_TEST);
//     // 3D  -> pakai Canvas3D:  PGraphics g = cv.begin();  ...gambar dengan g.xxx...  cv.end();
//     //        (field class:  Canvas3D cv = new Canvas3D();)  lihat el_Tunnel.pde sebagai contoh
//     // t.beat, t.frac, t.newBeat, t.inBeat(a,b), t.progress(a,b) bisa dipakai di sini
//   }
// }
//
// Lalu di pa_mv.pde:
//   deklarasi:  ElHujan hujan;
//   setup():    hujan = new ElHujan();
//   draw():     if (clock.inBeat(32, 48)) hujan.show(clock);
// =====================================================================
