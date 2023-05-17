class Pollen {
  float[][] points;
  float[] mass;

  final int count = 4096; // points to draw
  final int complexity = 8; // wind complexity
  final float maxMass = .8; // max pollen mass
  final float timeSpeed = .02; // wind variation speed
  final float phase = TWO_PI; // separate u-noise from v-noise
  //final float pollen_windSpeed = 40; // wind vector magnitude for debug
  //final int pollen_step = 10; // spatial sampling rate for debug

  Pollen(int height, int width) {
    points = new float[count][2];
    mass = new float[count];

    for (int i = 0; i < count; i++) {
      points[i] = new float[]{random(0, width), random(0, height)};
      mass[i] = random(0, maxMass);
    }
  }
}
