// Image segmentation via k-means clustering
// http://www.onmyphd.com/?p=k-means.clustering

PImage img;

class KMeansSegmentation {
  ArrayList<PVector> centers;
  color[] centercols;
  //double[][] distances;
  int[][] cluster;
  PGraphics pg;

  KMeansSegmentation(PGraphics ppg) {
    pg = ppg;
    centers = new ArrayList<PVector>();
    //distances = new double[width][height];
    cluster = new int[width][height];
    for (int x = 0; x < width; x++)
      for (int y = 0; y < height; y++)
        cluster[x][y] = -1;
  }

  void init_points_random(int n) {
    centercols = new color[n];
    for (int i = 0; i < n; i++) {
      centers.add(new PVector(random(width), random(height)));
      centercols[i] = color(0, 0, 0);
    }
  }

  double get_color_distance(color a, color b) {
    float r1 = a >> 16 & 0xFF;
    float g1 = a >> 16 & 0xFF;
    float b1 = a >> 16 & 0xFF;
    float r2 = b >> 16 & 0xFF;
    float g2 = b >> 16 & 0xFF;
    float b2 = b >> 16 & 0xFF;
    return sqrt(sq(r1-r2) + sq(g1-g2) + sq(b1-b2));
  }
  
  double get_color_distance2(color a, color b) {
    float rbar = (red(a) + red(b)) / 2;
    float deltar = red(a) - red(b);
    float deltag = green(a) - green(b);
    float deltab = blue(a) - blue(b);
    float deltac = sqrt(
                      2 * sq(deltar) +
                      4 * sq(deltag) +
                      3 * sq(deltab) +
                      (rbar + (sq(deltar) - sq(deltab)))/256); 
    return deltac;
  }

  int iteration() {
    pg.beginDraw();
    pg.loadPixels();
    int changed = 0;
    ArrayList<PVector> centersums = new ArrayList<PVector>();
    int[] centertotals = new int[centers.size()];
    float[] rtotals = new float[centers.size()];
    float[] gtotals = new float[centers.size()];
    float[] btotals = new float[centers.size()];
    for (int k = 0; k < centers.size(); k++) {
      centersums.add(new PVector(0, 0));
      centertotals[k] = 0;
      rtotals[k] = 0;
      gtotals[k] = 0;
      btotals[k] = 0;
    }

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int curr_cluster = cluster[x][y];
        //color cp = get(x, y);
        color cp = pg.pixels[y * pg.width + x];
        double closest_dist = 999999999;
        int closest_cluster = -1;
        for (int k = 0; k < centers.size(); k++) {
          //PVector center = centers.get(k);
          color cc = centercols[k];//get(int(center.x), int(center.y));
          double dist = get_color_distance2(cp, cc);
          //println(x + "," + y + ": dist: " + dist);
          if (dist < closest_dist) {
            closest_dist = dist;
            closest_cluster = k;
          }
        }
        cluster[x][y] = closest_cluster;
        //println("assigning cluster: (" + x + ", " + y + "): " + closest_cluster);
        centersums.get(closest_cluster).x += x;
        centersums.get(closest_cluster).y += y;
        centertotals[closest_cluster]++;
        rtotals[closest_cluster] += red(cp);
        gtotals[closest_cluster] += green(cp);
        btotals[closest_cluster] += blue(cp);
        if (closest_cluster != curr_cluster)
          changed++;
      }
    }
    pg.endDraw();
    /* Recalculate cluster centers */
    //ArrayList<PVector> new_centers = new ArrayList<PVector>();
    int n = centers.size();
    centers.clear();
    for (int k = 0; k < n; k++) {
      int cx = int(centersums.get(k).x / centertotals[k]);
      int cy = int(centersums.get(k).y / centertotals[k]);
      centers.add(new PVector(cx, cy));
      centercols[k] = color(
        rtotals[k] / centertotals[k], 
        gtotals[k] / centertotals[k], 
        btotals[k] / centertotals[k]
        );
      //println(cx + "," + cy);
    }
    //centers = new_centers;

    return changed;
  }

  void display() {
    //float golden_ratio_conjugate = 0.618033988749895;
    //float h = 0.5;
    for (int k = 0; k < centers.size(); k++) {
      noStroke();
      fill(centercols[k]);
      ellipse(centers.get(k).x, centers.get(k).y, 10, 10);
      //h += golden_ratio_conjugate;
      //h %= 1;
    }
  }

  PGraphics overlay() {
    PGraphics o = createGraphics(pg.width, pg.height);
    float min = 256, max = -1;
    for (int k = 0; k < centers.size(); k++) {
      println(centercols[k]);
      color c = centercols[k];
      if (red(c) < min)  
        min = red(c);
      if (red(c) > max)  
        max = red(c);
    }
    colorMode(HSB);
    println(min + "," + max);
    o.beginDraw();
    o.loadPixels();
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int curr_cluster = cluster[x][y];
        color c = color(map(red(centercols[curr_cluster]), min, max, 0, 255));
        if (red(centercols[curr_cluster]) != min && red(centercols[curr_cluster]) != max)
          c = color(127);
        //if (curr_cluster == 0) {
        //o.stroke(map(red(centercols[curr_cluster]), min, max, 0, 255));
        //o.stroke(centercols[curr_cluster]);
        o.pixels[y*o.width + x] = c;
        //}
      }
    }
    o.updatePixels();
    o.endDraw();
    println("");
    return o;
  }
};

void initimage(PGraphics pg) {
  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.filter(GRAY);
  pg.filter(BLUR, 2);
  pg.endDraw();
}

KMeansSegmentation kms;
boolean stop = false;
int n = 3;
PGraphics last;
PGraphics orig;

void setup() {
  size(500, 500);
  orig = createGraphics(width, height); 
  img = loadImage("portrait11.jpg");

  initimage(orig);
  gen();
}

void gen() {
  background(255);
  kms = new KMeansSegmentation(orig);
  kms.init_points_random(n);
  while (kms.iteration() > 0);
  last = kms.overlay();
  image(last, 0, 0);
  println("iteration " + n + " completed");
  n++;
}

void draw() {
  ////}
  ////void mouseClicked() {
  //background(255);
  //if (!stop) {
  //  //drawimage();
  //  image(kms.pg, 0, 0);

  //  int changed = kms.iteration();
  //  if (changed == 0)
  //    stop = true;

  //  println("Changed points: " + changed);
  //  kms.display();
  //} else {
  //  image(kms.overlay(), 0, 0);
  //}
}


void keyPressed() {
  if (key == 's') {
    saveFrame();
  }
}