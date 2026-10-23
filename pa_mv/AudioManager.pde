class AudioBeatManager {
  float bpm = 162;
  float beatDuration; 
  
  AudioBeatManager() {
    beatDuration = 60000.0 / bpm; 
  }
  
  int getBeat(float posMs) {
    return (int)(posMs / beatDuration);
  }
  
  int getSubBeat(float posMs) {
    return (int)(posMs / (beatDuration / 2));
  }
  
  // TAMBAHKAN INI: Untuk Layer 3 (1/4 ketukan)
  int getQuarterBeat(float posMs) {
    return (int)(posMs / (beatDuration / 4));
  }
  
  // TAMBAHKAN INI: Untuk Layer 4 (1/8 ketukan)
  int getEighthBeat(float posMs) {
    return (int)(posMs / (beatDuration / 8));
  }
}