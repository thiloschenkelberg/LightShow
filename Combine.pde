// import packages
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import java.util.Iterator;

// load packages
Capture video;
OpenCV opencv;

Minim minim;
AudioInput in;
FFT fft;

//// Set variables

// Effect
static boolean draw_faceTunnels = false;

static int currentEffect = 0;
static float lastEffectChangeTime = 0;
static final int effectDuration = 10000;

// Color
final color[] colors = {color(63, 50, 102), // Purple Heart
                      color(238, 66, 102), // Radical Red
                      color(131, 175, 155), // Eucalyptus
                      color(247, 190, 136), // Dark Salmon
                      color(174, 207, 158), // Granny Smith Apple
                      color(255, 121, 85), // Orange Red
                      color(89, 71, 140), // Eminence
                      color(208, 144, 173), // Mauvelous
                      color(177, 219, 231), // Powder Blue
                      color(255, 175, 123), // Peach
                      color(78, 205, 196), // Aquamarine
                      color(231, 111, 81), // Tomato
                      color(244, 162, 97), // Sandy Brown
                      color(255, 219, 171), // Lemon Chiffon
                      color(176, 196, 222), // Blue Bell
                      color(102, 102, 153), // Blue Violet
                      color(215, 159, 130), // Pink Sherbet
                      color(255, 213, 79), // Lemon Yellow
                      color(165, 105, 189), // Amethyst
                      color(244, 178, 156), // Light Apricot
                      color(69, 123, 157), // Steel Blue
                      color(255, 174, 153), // Light Coral
                      color(145, 71, 255), // Royal Purple
                      color(245, 215, 110), // Dandelion
                      color(91, 192, 222) // Maya Blue
};

static int currentColorIndex = 0;
static int nextColorIndex = 1;
static final float colorTransitionDuration = 2.0;
static float colorTransitionStartTime = 0;

// Moving Points
static Module[] modules;
static final int moving_points_unit = 40;
static int moving_points_count;

// Pollen
static Pollen pollen;
static boolean pollen_debugMode = false;

// Wavy
static float wavy_a = 0;

// Lines
static float lines_X = 0;
static float lines_Y = 0;

// Spiral Linepoint
static float[] spiral_linepoint_angles = {0, 0, 0, 0};
static float spiral_linepoint_angleSpeed = 0.1;
static float[] spiral_linepoint_radii = {150, 150, 150, 150};
static float spiral_linepoint_radiusSpeed = 0.1;
static float[] spiral_linepoint_sizes = {10, 10, 10, 10};
static float spiral_linepoint_sizeMultiplier = 200;
static float spiral_linepoint_maxRadius;

// Rotating Line
static float rotating_line_theta = 0;
static float rotating_line_hue = 0;

// Basic Circle / Circle Trio / Center
static float[] xPositions = new float[3];
static float[] yPositions = new float[3];
static float[] radii = new float[3];
static float[] angles = new float[3];
static float[] center_angles = {0, TWO_PI/3, 2*TWO_PI/3};
static final float basic_circles_angleStep = 0.5;
static final float circle_trio_angleStep = 0.05;
static final float center_angleStep = 0.5;
static final float center_circleSpeed = 50;

// Moving Spiral
static final int moving_spiral_bands = 256;
static final float moving_spiral_multiplier = 0.1;
static float[] moving_spiral_spectrum = new float[moving_spiral_bands];


// Pointline
static final int pointline_num = 60;
static float pointline_mx[] = new float[pointline_num];
static float pointline_my[] = new float[pointline_num];

// Starflower
static float[] starflower_bands;
static final int starflower_numBands = 8;

// FaceTunnels
ArrayList<Face> faces;


// Set Up
void setup() {
  smooth();
 
  //size(960, 540);
  fullScreen();

  // setup sound and video input
  setupSound();
  setupVideo();

  // setup for some effects
  setupModules();
  setupPollen();

  noiseDetail(14);

  // set start effect
  currentEffect = int(random(0,14));
  currentEffect = 0;

  faces = new ArrayList<Face>();
}

void draw() {
  // set background to black
  background(0); // 0 = black

  // Change Effect
  if (millis() - lastEffectChangeTime > effectDuration) {
    // Increment currentEffect and wrap around to 0 if it exceeds 2
    currentEffect = (currentEffect + 1) % 15;
    effectSetup(currentEffect);
    // Update the last effect change time
    lastEffectChangeTime = millis();
  }
  
  // Change Color
  if ((millis() / 1000.0) - colorTransitionStartTime >= colorTransitionDuration) {
    colorTransitionStartTime = millis() / 1000.0;
    currentColorIndex = nextColorIndex;
    nextColorIndex = (nextColorIndex + 1) % colors.length;
  }

  if (draw_faceTunnels) {
    drawFaceTunnels();
  }
  
  // Switch Modes
  switch(currentEffect) {
    case 0:
      lines();
      break;
    case 1:
      opposing_rectangles();
      break;
    case 2:
      spiral_linepoint();
      break;
    case 3: 
      rotating_line();
      break;
    case 4: 
      basic_circles();
      break;   
    case 5: 
      bezier_lines();
      break;     
    case 6: 
      circle_trio();
      break;   
    case 7: 
      center();
      break;  
    case 8: 
      moving_points();
      break; 
    case 9: 
      moving_spiral();
      break; 
    case 10: 
      pointline();
      break; 
    case 11: 
      vurp();
      break; 
    case 12: 
      starflower();
      break; 
    case 13: 
      wavy();
      break; 
    case 14: 
      drawPollen();
      break;
    default:
      break;
  }
}

////////// Effects Setup //////////
void effectSetup(int effect) {
  switch(effect) {
    case 4:
      basic_circle_setup();
      break;
    case 6:
      circle_trio_setup();
      break;
    case 7:
      center_setup();
      break;
    case 10:
      break;
    case 12:
      colorMode(RGB, 255);
      break;
    case 14:
      colorMode(RGB, 255);
      break;
    default:
      break;
  }
}

// Setup for Basic Circles
void basic_circle_setup() {
    // set the initial positions to the center of the screen
    for (int i = 0; i < 3; i++) {
    radii[i] = height / 8.0;
    angles[i] = i * TWO_PI / 3.0;
    xPositions[i] = width / 2;
    yPositions[i] = height / 2;
  }
}

// Setup for Circle Trio
void circle_trio_setup() {
  // set the initial positions
  for (int i = 0; i < 2; i++) {
    xPositions[i] = width / 2.0;
    yPositions[i] = height / 2.0;
    radii[i] = height / 4.0;
    angles[i] = i * TWO_PI / 3.0;
  }
}

// Setup for Center
void center_setup() {
  for (int i = 0; i < 1; i++) {
    xPositions[i] = width / 2.0 + i * width / 2.0;
    yPositions[i] = height / 2.0;
    radii[i] = height / 10.0;
  }
}

// Setup for Moving Points
void setupModules() {
  int mp_columns = width / moving_points_unit;
  int mp_rows = height / moving_points_unit;
  moving_points_count = mp_columns * mp_rows;
  modules = new Module[moving_points_count];

  int index = 0;
  for (int y = 0; y < mp_rows; y++) {
    for (int x = 0; x < mp_columns; x++) {
      modules[index++] = new Module(x*moving_points_unit, y*moving_points_unit, moving_points_unit/2, moving_points_unit/2, random(0.05, 0.8), moving_points_unit);
    }
  }
}

// Setup for Pollen
void setupPollen() {
  pollen = new Pollen(height, width);
}

///////////// Effects /////////////

void drawFaceTunnels(){
  scale(4);

  opencv.loadImage(video);
  Rectangle[] newFaces = opencv.detect();

  for (Rectangle newFace : newFaces) {
    PVector newFacePos = new PVector(1 * (newFace.x + (newFace.width / 2)),
                                     1 * (newFace.y + (newFace.height / 2)));
    float newFaceRadius = 0.75 * newFace.height;
    boolean faceMatch = false;

    for (Face face : faces) {
      if (face.match(newFacePos)) {
        face.update(newFacePos, newFaceRadius);
        faceMatch = true;
      }
    }

    if (!faceMatch) {
      faces.add(0, new Face(newFacePos, newFaceRadius));
    }
  }

  noFill();
  strokeWeight(1);

  /// Show webcam footage ///
  //image(video, 0, 0);

  Iterator<Face> faceIt = faces.iterator();
  while(faceIt.hasNext()) {
    Face face = faceIt.next();
    if (face.inactive()) {
      faceIt.remove();
    } else {
      boolean overlap = false;
      for (Face otherFace : faces) {
        if (face != otherFace && face.match(otherFace.getPosition(), 2)) {
          overlap = true;
        }
      }
      if (overlap) {
        faceIt.remove();
      }
      face.draw();
    }
  }

  scale(0.25);
}

void lines(){
  
  strokeWeight(8);
  // get the current audio level from the microphone
  float[] audioData = in.mix.toArray();
  float rms = 0;
  for (int i = 0; i < audioData.length; i++) {
    rms += audioData[i] * audioData[i];
  }
  rms /= audioData.length;
  rms = sqrt(rms);
  float micLevel = map(rms, 0, 0.5, 0, 10);

  // map the audio level to the position of the lines
  lines_X = map(micLevel, 0, 10, 0, width);
  lines_Y = map(micLevel, 0, 10, 0, height);

  // draw the lines
  stroke(colors[currentColorIndex]);
  line(lines_X, 0, lines_X, height);
  line(0, lines_Y, width, lines_Y);
}

void opposing_rectangles(){
  noStroke();
  rectMode(CENTER);
  float level = in.left.level(); // get the input level from the left channel
  float vari = map(level, 0, 1, 0, width);

  float r1 = map(vari, 0, width, 0, height);
  float r2 = height - r1;

  fill(colors[currentColorIndex]);
  rect(width/2 + r1/2, height/2, r1, r1);

  fill(colors[(currentColorIndex+1)%colors.length]);
  rect(width/2 - r2/2, height/2, r2, r2);
}

void spiral_linepoint(){
  spiral_linepoint_maxRadius = min(width, height) / 2 - max(spiral_linepoint_sizes) - 10;
  // Update angles, radii, and sizes based on audio input
  float level = in.mix.level();
  for (int i = 0; i < spiral_linepoint_angles.length; i++) {
    spiral_linepoint_angles[i] += level * spiral_linepoint_angleSpeed * (i+1);
    spiral_linepoint_radii[i] += level * spiral_linepoint_radiusSpeed * (i+1);
    spiral_linepoint_sizes[i] = level * spiral_linepoint_sizeMultiplier * (i+1);
  }
  
  // Find the maximum radius that keeps all spiral points within the bounds of the window
  float currentMaxRadius = max(spiral_linepoint_radii) + max(spiral_linepoint_sizes) + 10;
  spiral_linepoint_maxRadius = min(spiral_linepoint_maxRadius, currentMaxRadius);
  
  // Draw the spiral
  noFill();
  stroke(colors[(currentColorIndex+5) % colors.length]);
  strokeWeight(2);
  beginShape();
  for (int i = 0; i < spiral_linepoint_angles.length; i++) {
    float x = width/2 + cos(spiral_linepoint_angles[i]) * spiral_linepoint_radii[i];
    float y = height/2 + sin(spiral_linepoint_angles[i]) * spiral_linepoint_radii[i];
    float size = spiral_linepoint_sizes[i];
    float d = dist(x, y, width/2, height/2);
    if (d > spiral_linepoint_maxRadius) {
      // If the spiral point is outside the maximum radius, shrink it
      size *= spiral_linepoint_maxRadius / d;
    }
    vertex(x, y);
  }
  endShape();
  
  // Shrink the maximum radius gradually to make the spiral contract
  if (spiral_linepoint_maxRadius > min(width, height) / 4) {
    spiral_linepoint_maxRadius -= 1;
  }
  
  // Draw the spiral points
  fill(colors[currentColorIndex]);
  noStroke();
  for (int i = 0; i < spiral_linepoint_angles.length; i++) {
    float x = width/2 + cos(spiral_linepoint_angles[i]) * spiral_linepoint_radii[i];
    float y = height/2 + sin(spiral_linepoint_angles[i]) * spiral_linepoint_radii[i];
    float size = spiral_linepoint_sizes[i];
    float d = dist(x, y, width/2, height/2);
    if (d > spiral_linepoint_maxRadius) {
      // If the spiral point is outside the maximum radius, shrink it
      size *= spiral_linepoint_maxRadius / d;
    }
    ellipse(x, y, size, size);
  }

  if (spiral_linepoint_radiusSpeed > 0){
    spiral_linepoint_radiusSpeed = -0.1;
  }
  else {
    spiral_linepoint_radiusSpeed = 0.1;
  }
}

void rotating_line(){
  strokeWeight(2);
  translate(width/2, height/2);
  
  // Get the amplitude of the audio input
  float level = in.mix.level();
  
  // Calculate the angle of rotation based on the amplitude
  float rotation = map(level, 0, 1, 0, TWO_PI);
  rotating_line_theta += rotation;
  
  // Calculate the hue based on the angle of rotation
  rotating_line_hue = map(rotating_line_theta, 0, TWO_PI, colors[currentColorIndex], 0) % 360;
  
  // Set the stroke color based on the hue
  stroke(rotating_line_hue, 5, 500);
  
  // Draw a line from the center of the screen to a point on the circumference of a circle
  float x = cos(rotating_line_theta) * width/2;
  float y = sin(rotating_line_theta) * height/2;
  line(0, 0, x, y);
}

void basic_circles(){
  strokeWeight(2);
  // draw each circle in a separate color
  for (int i = 0; i < 3; i++) {
    stroke(colors[(currentColorIndex+i) % colors.length]);
    noFill();
    beginShape();
    float[] wave = in.mix.toArray();
    int waveSize = wave.length;
    float angle = 0;
    for (int j = 0; j < waveSize; j++) {
      angle += basic_circles_angleStep;
      if (angle > TWO_PI) {
        angle = 0;
      }
      float x = xPositions[i] + radii[i] * cos(angles[i] + angle);
      float y = yPositions[i] + radii[i] * sin(angles[i] + angle);
      float amp = map(abs(wave[j]), 0, 1, 0, radii[i]);
      ellipse(x, y, amp, amp);
    }
    endShape();
  }
  
  // update circle positions
  for (int i = 0; i < 3; i++) {
    float speed = map(abs(fft.getBand(i+1)), 0, 1, 0, 1);
    xPositions[i] += speed * cos(angles[i]);
    yPositions[i] += speed * sin(angles[i]);
    if (xPositions[i] < 0 - radii[i] || xPositions[i] > width + radii[i]) {
      xPositions[i] = random(width);
    }
    if (yPositions[i] < 0 - radii[i] || yPositions[i] > height + radii[i]) {
      yPositions[i] = random(height);
    }
    angles[i] += basic_circles_angleStep;
    if (angles[i] > TWO_PI) {
      angles[i] = 0;
    }
  }
}

void bezier_lines(){
  strokeWeight(2);
  stroke(colors[(currentColorIndex+4) % colors.length]);
  noFill();
  float micLevel = in.mix.level(); // get the current audio level of the microphone input
  float x = map(micLevel, 0, 1, 0, width); // map the mic level to the x-coordinate of the processing body
  rotate(0.001); // rotate the form at a constant speed
  
  // Draw the first Bezier curve
  for (int i = 0; i < 200; i += 20) {
    bezier(x-(i/8.0), 200+i, 410, 100, 100, 100, 240-(i/16.0), 600+(i/2.0));
  }
  
  // Draw the mirrored Bezier curve on the right side
  pushMatrix(); // save the current transformation state
  translate(width, 0); // move the origin to the right edge of the screen
  scale(-1, 1); // flip the x-axis
  for (int i = 0; i < 200; i += 20) {
    bezier(x-(i/8.0), 200+i, width-410, 100, width-100, 100, width-240+(i/16.0), 600+(i/2.0));
  }
  popMatrix(); // restore the previous transformation state
  scale(-1,1);
}

void circle_trio(){
  strokeWeight(2);
  //circle_trio_setup();
  fft.forward(in.mix);
  stroke(colors[(currentColorIndex+10) % colors.length]);
  noFill();
  float[] wave = in.mix.toArray();
  int waveSize = wave.length;
  float angle = 0;
  beginShape();
  for (int i = 0; i < waveSize; i++) {
    angle += circle_trio_angleStep;
    if (angle > TWO_PI) {
      angle = 0;
    }
    for (int j = 0; j < 2; j++) {
      float x = xPositions[j] + radii[j] * cos(angles[j] + angle);
      float y = yPositions[j] + radii[j] * sin(angles[j] + angle);
      float yMapped = map(wave[i], -1, 1, 0, radii[j]);
      vertex(x, y + yMapped);
    }
  }
  endShape();
  
  // update circle positions
  for (int i = 0; i < 2; i++) {
    xPositions[i] += 2 * cos(angles[i]);
    yPositions[i] += 2 * sin(angles[i]);
    angles[i] += circle_trio_angleStep;
    if (angles[i] > TWO_PI) {
      angles[i] = 0;
    }
  }
}

void center(){
  strokeWeight(2);
  // draw each circle in a separate color
  for (int i = 0; i < 1; i++) {
    stroke(colors[(currentColorIndex+i) % colors.length]);
    noFill();
    beginShape();
    float angle = 0;
    for (int j = 0; j < 60; j++) {
      angle += center_angleStep;
      float x = xPositions[i] + radii[i] * cos(center_angles[i] + angle);
      float y = yPositions[i] + radii[i] * sin(center_angles[i] + angle);
      float amp = map(j, 0, 30, 0, radii[i]);
      ellipse(x, y, amp, amp);
    }
    endShape();
  }
  
  // update circle positions
  for (int i = 0; i < 1; i++) {
    center_angles[i] += center_circleSpeed * center_angleStep;
    if (center_angles[i] > TWO_PI) {
      center_angles[i] -= TWO_PI;
    }
    float circleX = width / 2.0 + (width / 3.0) * cos(center_angles[i]);
    float circleY = height / 2.0 + (height / 3.0) * sin(center_angles[i]);
    xPositions[i] = circleX + radii[i] * cos(center_angles[i]);
    yPositions[i] = circleY + radii[i] * sin(center_angles[i]);
  }
}

void moving_points(){
  noStroke();
  for (Module mod : modules) {
    mod.update();
    mod.display();
  }
}

void moving_spiral(){
  noStroke();
  fill(colors[currentColorIndex]);
  // analyze the audio input
  fft.forward(in.mix);
  for (int i = 0; i < moving_spiral_bands; i++) {
    moving_spiral_spectrum[i] = fft.getBand(i);
  } 
  // calculate the average amplitude of the spectrum
  float amplitude = 0;
  for (int i = 0; i < moving_spiral_bands; i++) {
    amplitude += moving_spiral_spectrum[i];
  }
  amplitude /= moving_spiral_bands;
  
  // adjust the radius of the circles based on the amplitude
  float radius = 10 + amplitude * 1000 * moving_spiral_multiplier;
  if (radius > 200) {
    radius = 200;
  }
  
  // draw the circles
  for (int grad = 0; grad < 3600; grad += 12) {
    float angle = radians(grad);
    float x = 700 + cos(angle) * radius;
    float y = 400 + sin(angle) * radius;
    ellipse(x, y, 7, 7);
    radius += 2;
  }
}

void pointline(){
  noStroke();
  fill(colors[(currentColorIndex+11) % colors.length]); 
  
  int which = frameCount % pointline_num;
  pointline_mx[which] = map(in.left.get(0), -1, 1, 0, width);
  pointline_my[which] = map(in.right.get(0), -1, 1, 0, height);
  
  for (int i = 0; i < pointline_num; i++) {
    int index = (which+1 + i) % pointline_num;
    ellipse(pointline_mx[index], pointline_my[index], i, i);
  }
}

void vurp(){
  strokeWeight(2);
  stroke(colors[(currentColorIndex+9) % colors.length]);
  pushMatrix();
  translate(width/2, height/2);
  rotate(frameCount * 0.01);
  for (int x = 10; x < 120; x += 20) {
    float scaleFactor = map(sin(frameCount * 0.05), -1, 1, 0.5, 1.5); // scale based on sin wave
    scale(scaleFactor);
    line(125, x, x+130, 125);
    line(125, x+130, x, 125);
    line(125, 120-x, x, 125);
    line(125, 250-x, x+130, 125);
  }
  popMatrix();
}

void starflower(){
  noStroke();
  fft.forward(in.mix);
  fft.logAverages(22, starflower_numBands);

  // move the origin to the center of the screen
  translate(width/3, height/3);
  
  starflower_bands = new float[starflower_numBands];
  for (int i = 0; i < starflower_numBands; i++) {
    float band = fft.getBand(i);
    starflower_bands[i] = lerp(starflower_bands[i], band, 0.2);
  }

  for (int x = 880; x > 0; x -= 10) {
    rect(0, 0, x, x);
    float hue = map(starflower_bands[(int) map(x, 0, 880, 0, starflower_numBands - 1)], 0, 1, 0, 255);
    println(hue);
    fill(hue, 25, 70, 50);
    rotate(PI / 6);
  }
}

void wavy(){
  strokeWeight(1);
  stroke(colors[(currentColorIndex+6) % colors.length]);
  colorMode(RGB, 6);
  wavy_a -= 0.08;
  for (int x = -7; x < 7; x++) {
   for (int z = -7; z < 7; z++) {
    int y = int(24 * cos(0.55 * distance(x,z,0,0) + wavy_a));
    
    float xm = x*17 -8.5;
    float xt = x*17 +8.5;
    float zm = z*17 -8.5;
    float zt = z*17 +8.5;
    
    /* We use an integer to define the width and height of the window. This is used to save resources on further calculating */
    int halfw = (int)width/2;
    int halfh = (int)height/2;
    
    int isox1 = int(xm - zm + halfw);
    int isoy1 = int((xm + zm) * 0.5 + halfh);
    int isox2 = int(xm - zt + halfw);
    int isoy2 = int((xm + zt) * 0.5 + halfh);
    int isox3 = int(xt - zt + halfw);
    int isoy3 = int((xt + zt) * 0.5 + halfh);
    int isox4 = int(xt - zm + halfw);
    int isoy4 = int((xt + zm) * 0.5 + halfh);
    
    /* The side quads. 2 and 4 is used for the coloring of each of these quads */
    fill (colors[(currentColorIndex+2) % colors.length]);
    quad(isox2, isoy2-y, isox3, isoy3-y, isox3, isoy3+40, isox2, isoy2+40);
    fill (colors[(currentColorIndex+9) % colors.length]);
    quad(isox3, isoy3-y, isox4, isoy4-y, isox4, isoy4+40, isox3, isoy3+40);

    fill(colors[(currentColorIndex+6) % colors.length] + y * 0.05);
    quad(isox1, isoy1-y, isox2, isoy2-y, isox3, isoy3-y, isox4, isoy4-y);
   }
  }
}
/* The distance formula */
float distance(float x,float y,float cx,float cy) {
  return sqrt(sq(cx - x) + sq(cy - y));
}

void drawPollen(){
  strokeWeight(2);
  stroke(colors[(currentColorIndex+6) % colors.length]);

  float t = frameCount * pollen.timeSpeed;

  for(int i = 0; i < pollen.count; i++) {
    float x = pollen.points[i][0];
    float y = pollen.points[i][1];
    float normx = norm(x, 0, width);
    float normy = norm(y, 0, height);
    float u = noise(t + pollen.phase, normx * pollen.complexity + pollen.phase, normy * pollen.complexity + pollen.phase);
    float v = noise(t - pollen.phase, normx * pollen.complexity - pollen.phase, normy * pollen.complexity + pollen.phase);
    float speed = (1 + noise(t, u, v)) / pollen.mass[i];
    x += lerp(-speed, speed, u);
    y += lerp(-speed, speed, v);
    
    if(x < 0 || x > width || y < 0 || y > height) {
      x = random(0, width);
      y = random(0, height);
    }

    pollen.points[i][0] = x;
    pollen.points[i][1] = y;
    
    point(x, y);
  }
}

/////////// Setup ////////////

void setupSound() {
  // create a new Minim object
  minim = new Minim(this);

  // get the default audio input device
  in = minim.getLineIn(Minim.MONO, 512);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(60, 7);
}

void setupVideo() {
  video = new Capture(this, 480, 270);
  opencv = new OpenCV(this, 480, 270);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  video.start();
}

////// IO //////

void mousePressed() {
  setup();
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      if (currentEffect > 0) {
        currentEffect--;
      } else {
        currentEffect = 14;
      }
      effectSetup(currentEffect);
      lastEffectChangeTime = millis();
    } else if (keyCode == RIGHT) {
      currentEffect = (currentEffect + 1) % 15;
      effectSetup(currentEffect);
      lastEffectChangeTime = millis();
    }
  }
  
  switch (key) {
    case 'd':
      pollen_debugMode = !pollen_debugMode;
      if (pollen_debugMode) {
        background(255);
      } else {
        background(0);
      }
      break;
    case 'w':
      draw_faceTunnels = true;
      break;
    case 'l':
      draw_faceTunnels = false;
      break;
    case '0':
      background(0);
      break;
    default:
      break;
  }

}

void captureEvent(Capture c) {
  c.read();
}
