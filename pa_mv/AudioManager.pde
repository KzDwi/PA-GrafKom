class AudioBeatManager {
  float bpm = 162;
  float beatDuration; // dalam milidetik
  
  AudioBeatManager() {
    beatDuration = 60000.0 / bpm; // 60000ms / 162 = ~370ms
  }
  
  // Fungsi untuk mendapatkan beat saat ini (0, 1, 2, dst)
  int getBeat(float posMs) {
    return (int)(posMs / beatDuration);
  }
  
  // Fungsi untuk sub-beat (misal 2x lebih cepat)
  int getSubBeat(float posMs) {
    return (int)(posMs / (beatDuration / 2));
  }
}