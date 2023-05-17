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

Capture video;
OpenCV opencv;

// load packages
Minim minim;
AudioInput in;
FFT fft;

// Set variables
int currentFunction = 0;
float lastFunctionChangeTime = 0;

float wavy_a;

int[] colors = {color(63, 50, 102), // Purple Heart
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

int currentColorIndex = 0;
int nextColorIndex = 1;
float colorTransitionDuration = 5.0;
float colorTransitionStartTime = 0;

float lines_X = 0;
float lines_Y = 0;

float[] spiral_linepoint_angles = {0, 0, 0, 0};
float spiral_linepoint_angleSpeed = 0.1;
float[] spiral_linepoint_radii = {150, 150, 150, 150};
float spiral_linepoint_radiusSpeed = 0.1;
float[] spiral_linepoint_sizes = {10, 10, 10, 10};
float spiral_linepoint_sizeMultiplier = 200;
float spiral_linepoint_maxRadius;

float rotating_line_theta = 0;
float rotating_line_hue = 0;

float[] basic_circles_xPositions = new float[3];
float[] basic_circles_yPositions = new float[3];
float[] basic_circles_radii = new float[3];
float[] basic_circles_angles = new float[3];
float basic_circles_angleStep = 0.5;

float[] circle_trio_xPositions = new float[3];
float[] circle_trio_yPositions = new float[3];
float[] circle_trio_radii = new float[3];
float[] circle_trio_angles = new float[3];
float circle_trio_angleStep = 0.05;

float[] center_xPositions = new float[3];
float[] center_yPositions = new float[3];
float[] center_radii = new float[3];
float[] center_angles = {0, TWO_PI/3, 2*TWO_PI/3};
float center_angleStep = 0.5;
float center_circleSpeed = 50;

int moving_points_unit = 40;
int moving_points_count;
Module[] mods;

int moving_spiral_bands = 256;
float[] moving_spiral_spectrum = new float[moving_spiral_bands];
float moving_spiral_multiplier = 0.1;

int pointline_num = 60;
float pointline_mx[] = new float[pointline_num];
float pointline_my[] = new float[pointline_num];

float[] starflower_bands;
int starflower_numBands = 8;

int pollen_nPoints = 4096; // points to draw
float pollen_complexity = 8; // wind complexity
float pollen_maxMass = .8; // max pollen mass
float pollen_timeSpeed = .02; // wind variation speed
float pollen_phase = TWO_PI; // separate u-noise from v-noise

float pollen_windSpeed = 40; // wind vector magnitude for debug
int pollen_step = 10; // spatial sampling rate for debug

float[] pollen_pollenMass;
float[][] pollen_points;

boolean pollen_debugMode = false;

float xPos, yPos;
float radius = 35;
float angle = 0;
float saturation = 100; // saturation of the color
float brightness = 100; // brightness of the color
int numSegments = 8; // number of segments in the circle outline
float segmentAngle = 360.0 / numSegments; // angle of each segment

// Set Up
void setup() {
  smooth();
  video = new Capture(this, 480, 270);
  opencv = new OpenCV(this, 480, 270);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  
  video.start();
 

  size(960, 540);
  //fullScreen();

  // create a new Minim object
  minim = new Minim(this);

  // get the default audio input device
  in = minim.getLineIn(Minim.MONO, 512);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(60, 7);
  
  stroke(colors[currentColorIndex+3]);
  int wideCount = width / moving_points_unit;
  int highCount = height / moving_points_unit;
  moving_points_count = wideCount * highCount;
  mods = new Module[moving_points_count];

  int index = 0;
  for (int y = 0; y < highCount; y++) {
    for (int x = 0; x < wideCount; x++) {
      mods[index++] = new Module(x*moving_points_unit, y*moving_points_unit, moving_points_unit/2, moving_points_unit/2, random(0.05, 0.8), moving_points_unit);
    }
  }
  pollen_points = new float[pollen_nPoints][2];
  pollen_pollenMass = new float[pollen_nPoints];
  for(int i = 0; i < pollen_nPoints; i++) {
    pollen_points[i] = new float[]{random(0, width), random(0, height)};
    pollen_pollenMass[i] = random(0, pollen_maxMass);
  }
  noiseDetail(14);
}

void draw() {
  // set backgorund to black
  background(0); // 0 = black

  // Change Function
  if (millis() - lastFunctionChangeTime > 5000) {
    // Increment currentFunction and wrap around to 0 if it exceeds 2
    currentFunction = (currentFunction + 1) % 15;
    // Update the last function change time
    lastFunctionChangeTime = millis();
  }
  
  // Change Color
  float currentTime = millis() / 3000.0;
  if (currentTime - colorTransitionStartTime >= colorTransitionDuration) {
    colorTransitionStartTime = currentTime;
    currentColorIndex = nextColorIndex;
    nextColorIndex = (nextColorIndex + 1) % colors.length;
  }
  
  // Switch Modes
  switch(15) {
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
      pollen();
      break; 
    case 15:
      crazy();
      break;
  }
}





///////////// Different Functions /////////



void crazy(){
  opencv.loadImage(video);
  Rectangle[] faces = opencv.detect();
  
  //image(video, 0, 0);
  scale(2);
  noFill();
  strokeWeight(1);
  
  for (int i = 0; i < faces.length; i++) {
    xPos = faces[i].x + (faces[i].width / 2);
    yPos = faces[i].y + (faces[i].height / 2);
    for (int j = 0; j < numSegments; j++) {
      float startAngle = j * segmentAngle + angle;
      float endAngle = (j + 1) * segmentAngle + angle;
      
      stroke(colors[1]);
      if (j % 2 == 0) {
        stroke(colors[17]);
      }

      arc(xPos,yPos, radius*2, radius*2, radians(startAngle), radians(endAngle));

    }
    //rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
  }
  
  println(xPos);
  
  angle = (angle + 0.25) % 360;
  
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

  fill(colors[currentColorIndex+1]);
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
  stroke(colors[currentColorIndex]+5);
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

  // set the initial positions to the center of the screen
  for (int i = 0; i < 3; i++) {
    basic_circles_radii[i] = height / 8.0;
    basic_circles_angles[i] = i * TWO_PI / 3.0;
    basic_circles_xPositions[i] = width / 2;
    basic_circles_yPositions[i] = height / 2;
  }

  // draw each circle in a separate color
  for (int i = 0; i < 3; i++) {
    stroke(colors[currentColorIndex+i]);
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
      float x = basic_circles_xPositions[i] + basic_circles_radii[i] * cos(basic_circles_angles[i] + angle);
      float y = basic_circles_yPositions[i] + basic_circles_radii[i] * sin(basic_circles_angles[i] + angle);
      float amp = map(abs(wave[j]), 0, 1, 0, basic_circles_radii[i]);
      ellipse(x, y, amp, amp);
    }
    endShape();
  }
  
  // update circle positions
  for (int i = 0; i < 3; i++) {
    float speed = map(abs(fft.getBand(i+1)), 0, 1, 0, 1);
    basic_circles_xPositions[i] += speed * cos(basic_circles_angles[i]);
    basic_circles_yPositions[i] += speed * sin(basic_circles_angles[i]);
    if (basic_circles_xPositions[i] < 0 - basic_circles_radii[i] || basic_circles_xPositions[i] > width + basic_circles_radii[i]) {
      basic_circles_xPositions[i] = random(width);
    }
    if (basic_circles_yPositions[i] < 0 - basic_circles_radii[i] || basic_circles_yPositions[i] > height + basic_circles_radii[i]) {
      basic_circles_yPositions[i] = random(height);
    }
    basic_circles_angles[i] += basic_circles_angleStep;
    if (basic_circles_angles[i] > TWO_PI) {
      basic_circles_angles[i] = 0;
    }
  }
}

void bezier_lines(){
  stroke(colors[currentColorIndex+4]);
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
}

void circle_trio(){

  for (int i = 0; i < 2; i++) {
    circle_trio_xPositions[i] = width / 2.0;
    circle_trio_yPositions[i] = height / 2.0;
    circle_trio_radii[i] = height / 4.0;
    circle_trio_angles[i] = i * TWO_PI / 3.0;
  }
  fft.forward(in.mix);
  stroke(colors[currentColorIndex+10]);
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
      float x = circle_trio_xPositions[j] + circle_trio_radii[j] * cos(circle_trio_angles[j] + angle);
      float y = circle_trio_yPositions[j] + circle_trio_radii[j] * sin(circle_trio_angles[j] + angle);
      float yMapped = map(wave[i], -1, 1, 0, circle_trio_radii[j]);
      vertex(x, y + yMapped);
    }
  }
  endShape();
  
  // update circle positions
  for (int i = 0; i < 2; i++) {
    circle_trio_xPositions[i] += 2 * cos(circle_trio_angles[i]);
    circle_trio_yPositions[i] += 2 * sin(circle_trio_angles[i]);
    circle_trio_angles[i] += circle_trio_angleStep;
    if (circle_trio_angles[i] > TWO_PI) {
      circle_trio_angles[i] = 0;
    }
  }
}

void center(){
  for (int i = 0; i < 1; i++) {
    center_xPositions[i] = width / 2.0 + i * width / 2.0;
    center_yPositions[i] = height / 2.0;
    center_radii[i] = height / 10.0;
  }
  // draw each circle in a separate color
  for (int i = 0; i < 1; i++) {
    stroke(colors[currentColorIndex+i]);
    noFill();
    beginShape();
    float angle = 0;
    for (int j = 0; j < 60; j++) {
      angle += center_angleStep;
      float x = center_xPositions[i] + center_radii[i] * cos(center_angles[i] + angle);
      float y = center_yPositions[i] + center_radii[i] * sin(center_angles[i] + angle);
      float amp = map(j, 0, 30, 0, center_radii[i]);
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
    center_xPositions[i] = circleX + center_radii[i] * cos(center_angles[i]);
    center_yPositions[i] = circleY + center_radii[i] * sin(center_angles[i]);
  }
}

void moving_points(){
  for (Module mod : mods) {
    mod.update();
    mod.display();
  }
}

void moving_spiral(){
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
    ellipse(x, y, 15, 15);
    radius += 2;
  }
}

void pointline(){
  noStroke();
  fill(colors[currentColorIndex+11]); 
  
  int which = frameCount % pointline_num;
  pointline_mx[which] = map(in.left.get(0), -1, 1, 0, width);
  pointline_my[which] = map(in.right.get(0), -1, 1, 0, height);
  
  for (int i = 0; i < pointline_num; i++) {
    int index = (which+1 + i) % pointline_num;
    ellipse(pointline_mx[index], pointline_my[index], i, i);
  }
}

void vurp(){
  stroke(colors[currentColorIndex+9]);
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
  fft.forward(in.mix);
  fft.logAverages(22, starflower_numBands);
  noStroke();
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
    fill(hue, 25, 70, 50);
    rotate(PI / 6);
  }
}

void wavy(){
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
    fill (colors[currentColorIndex+2]);
    quad(isox2, isoy2-y, isox3, isoy3-y, isox3, isoy3+40, isox2, isoy2+40);
    fill (colors[currentColorIndex+9]);
    quad(isox3, isoy3-y, isox4, isoy4-y, isox4, isoy4+40, isox3, isoy3+40);

    fill(colors[currentColorIndex+6] + y * 0.05);
    quad(isox1, isoy1-y, isox2, isoy2-y, isox3, isoy3-y, isox4, isoy4-y);
   }
  }
}
/* The distance formula */
float distance(float x,float y,float cx,float cy) {
  return sqrt(sq(cx - x) + sq(cy - y));
}

void pollen(){
  float t = frameCount * pollen_timeSpeed;
 
  stroke(colors[currentColorIndex+6]);
  
  for(int i = 0; i < pollen_nPoints; i++) {
    float x = pollen_points[i][0];
    float y = pollen_points[i][1];
    
    float normx = norm(x, 0, width);
    float normy = norm(y, 0, height);
    float u = noise(t + pollen_phase, normx * pollen_complexity + pollen_phase, normy * pollen_complexity + pollen_phase);
    float v = noise(t - pollen_phase, normx * pollen_complexity - pollen_phase, normy * pollen_complexity + pollen_phase);
    float speed = (1 + noise(t, u, v)) / pollen_pollenMass[i];
    x += lerp(-speed, speed, u);
    y += lerp(-speed, speed, v);
    
    if(x < 0 || x > width || y < 0 || y > height) {
      x = random(0, width);
      y = random(0, height);
    }
    

    point(x, y);
      
    pollen_points[i][0] = x;
    pollen_points[i][1] = y;
  }
}

void mousePressed() {
  setup();
}

void keyPressed() {
  pollen_debugMode = !pollen_debugMode;
  background(255);
}

void captureEvent(Capture c) {
  c.read();
}
