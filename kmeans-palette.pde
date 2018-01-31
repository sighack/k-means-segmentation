// Image segmentation via k-means clustering
// http://www.onmyphd.com/?p=k-means.clustering

PImage img;

class KMeansSegmentation {
  int npoints;
  PGraphics image;
  color[] center_colors;
  int[][] cluster_assignments;

  KMeansSegmentation(PGraphics ppg) {
    image = ppg;
    cluster_assignments = new int[image.width][image.height];
    for (int x = 0; x <image.width; x++)
      for (int y = 0; y < image.height; y++)
        cluster_assignments[x][y] = -1;
  }

  void create_clusters(int n) {
    npoints = n;
    center_colors = new color[npoints];
    for (int i = 0; i < n; i++)
      center_colors[i] = color(255, 255, 255);
  }

  double cdist(color a, color b) {
    float r1 = a >> 16 & 0xFF;
    float g1 = a >> 16 & 0xFF;
    float b1 = a >> 16 & 0xFF;
    float r2 = b >> 16 & 0xFF;
    float g2 = b >> 16 & 0xFF;
    float b2 = b >> 16 & 0xFF;
    return sqrt(sq(r1-r2) + sq(g1-g2) + sq(b1-b2));
  }
  
  double cdist2(color a, color b) {
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
    int changed = 0;
    int[] totals = new int[npoints];
    float[][] ctotals = new float[npoints][3];

    for (int i = 0; i < npoints; i++) {
      totals[i] = 0;
      ctotals[i][0] = 0;
      ctotals[i][1] = 0;
      ctotals[i][2] = 0;
    }

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        int curr_cluster;  /* Currently-assigned cluster of pixel before iteration */
        color pixel_color; /* Color of the pixel at (x, y) */
        double closest_distance = 999999999;
        int closest_cluster = -1;
        
        curr_cluster = cluster_assignments[x][y];
        pixel_color = image.pixels[y * image.width + x];

        /* Iterate through clusters and figure out which is closest to this pixel */
        for (int i = 0; i < npoints; i++) {
          color cc = center_colors[i];
          double dist = cdist2(pixel_color, cc);
          if (dist < closest_distance) {
            closest_distance = dist;
            closest_cluster = i;
          }
        }
        
        /* Change the assignment of this pixel to newly-calculated closest cluster */
        cluster_assignments[x][y] = closest_cluster;
        
        /* Add the pixel's R, G, and B values to cluster totals */
        ctotals[closest_cluster][0] += red(pixel_color);
        ctotals[closest_cluster][1] += green(pixel_color);
        ctotals[closest_cluster][2] += blue(pixel_color);
        /* Increment the number of pixels assigned to cluster */
        totals[closest_cluster]++;
        
        /* If new cluster assignment is different from old, increment changed */
        if (closest_cluster != curr_cluster)
          changed++;
      }
    }

    /* Recalculate cluster centers. Calculate average color using 'ctotals' and 'totals' */
    for (int i = 0; i < npoints; i++) {
      center_colors[i] = color(
        ctotals[i][0] / totals[i], 
        ctotals[i][1] / totals[i], 
        ctotals[i][2] / totals[i]
      );
    }

    return changed;
  }

  PGraphics overlay() {
    PGraphics o = createGraphics(image.width, image.height);
    float min = 256, max = -1;
    for (int k = 0; k < npoints; k++) {
      println(center_colors[k]);
      color c = center_colors[k];
      if (red(c) < min)  
        min = red(c);
      if (red(c) > max)  
        max = red(c);
    }
    println(min + "," + max);
    o.beginDraw();
    o.loadPixels();
    for (int x = 0; x < o.width; x++) {
      for (int y = 0; y < o.height; y++) {
        int curr_cluster = cluster_assignments[x][y];
        color c = color(map(red(center_colors[curr_cluster]), min, max, 0, 255));
        if (red(center_colors[curr_cluster]) != min && red(center_colors[curr_cluster]) != max)
          c = color(127);
        o.pixels[y*o.width + x] = c;
      }
    }
    o.updatePixels();
    o.endDraw();
    return o;
  }
  
  PGraphics overlay_color() {
    PGraphics o = createGraphics(image.width, image.height);
    float min = 256, max = -1;
    for (int k = 0; k < npoints; k++) {
      println(center_colors[k]);
      color c = center_colors[k];
      if (red(c) < min)  
        min = red(c);
      if (red(c) > max)  
        max = red(c);
    }
    println(min + "," + max);
    o.beginDraw();
    o.loadPixels();
    for (int x = 0; x < o.width; x++) {
      for (int y = 0; y < o.height; y++) {
        int curr_cluster = cluster_assignments[x][y];
        o.pixels[y*o.width + x] = center_colors[curr_cluster];
      }
    }
    o.updatePixels();
    o.endDraw();
    return o;
  }
};

void initimage(PGraphics pg) {
  pg.beginDraw();
  pg.image(img, 0, 0);
  //pg.filter(GRAY);
  pg.filter(BLUR, 2);
  pg.endDraw();
}

KMeansSegmentation kms;
boolean stop = false;
int n = 5;
PGraphics last;
PGraphics orig;

void setup() {
  size(500, 500);
  orig = createGraphics(width, height); 
  img = loadImage("portrait6.jpg");

  initimage(orig);
  gen();
}

void gen() {
  background(255);
  kms = new KMeansSegmentation(orig);
  kms.create_clusters(n);
  while (kms.iteration() > 0);
  last = kms.overlay_color();
  image(last, 0, 0);
  println("iteration " + n + " completed");
  n++;
}

void draw() {}


void keyPressed() {
  if (key == 's') {
    saveFrame();
  }
}