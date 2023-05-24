class Face {
  int numSegments = 8;
  float segmentAngle = 360.0 / numSegments;
  float angle = 0;
  float angleTurnSpeed = 0.5;

  PVector position;
  float radius;
  int inactiveFrames = 0;

  Face(PVector position, float radius) {
    this.position = position;
    this.radius = radius;
  }

  PVector getPosition() {
    return position;
  }

  void update(PVector position, float radius) {
    this.position.lerp(position, 0.75);
    this.radius = lerp(this.radius, radius, 0.25);
    inactiveFrames = 0;
    angle = (angle + angleTurnSpeed) % 360;
  }

  boolean inactive() {
    return (inactiveFrames++ > 20);
  }

  boolean match(PVector position) {
    return this.position.dist(position) < radius * 2;
  }

  boolean match(PVector position, float allowedDistance) {
    return this.position.dist(position) < allowedDistance * radius;
  }

  void draw() {
    for (int i = 0; i < numSegments; i++) {
      float startAngle = i * segmentAngle + angle;
      float endAngle = (i + 1) * segmentAngle + angle;

      stroke(colors[1]);
      if (i % 2 == 0) {
        stroke(colors[17]);
      }

      pushMatrix();
      translate(position.x, position.y);
      rotate(radians(angle));
      
      arc(0, 0, radius*2, radius*2, radians(startAngle), radians(endAngle));

      line(0 - (0.5 * radius), 0 - (0.65 * radius), 0 + (0.5 * radius), 0 - (0.65 * radius));
      line(0 + (0.5 * radius), 0 - (0.65 * radius), 0 - (0.5 * radius), 0 + (0.65 * radius));
      line(0 - (0.5 * radius), 0 + (0.65 * radius), 0 + (0.5 * radius), 0 + (0.65 * radius));    

      popMatrix();
    }
  }
}