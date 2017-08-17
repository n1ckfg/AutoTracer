// http://forum.processing.org/one/topic/help-starting-bitmap-trace.html
// brush path code by Amnon Owed

PImage img;

int numDrawers = 1000; //points drawn per frame--use lots
int numDrawerReps = 1;//scatter points per point--use sparingly
int numStrokes = 10;
int numRepsMax = 200; // draw loops--to taste
int numReps = 0;
boolean ready = false;
String brushFile = "brush5";
PImage brush;
PVector p = new PVector(0, 0);
int alphaDecrease = 50;
float brushSizeOrig = 20;
float brushSize = brushSizeOrig;
float brushSizeMin = 5;
float brushSizeMax = 40;
float leakRandom = 0.2; //0-1
float scatter = 4;
PGraphics alphaImg;
PGraphics alphaImgOrig;
boolean firstRun = true;
boolean cleanOutlines = true;
boolean useBase = true;
float shrinkAmount = 0.99;
int counter = 0;

void setup() {
  Settings settings = new Settings("settings.txt");
  loadFiles();
  nextImage(counter);
  size(50,50);
  surface.setSize(img.width, img.height);
  brush = loadImage(brushFile+".png");
  brush.filter(INVERT);
}

void draw() {
  //prep graphics
  if (firstRun) {
    prepGraphics();

    println("RENDERING frame " + (counter+1) + " of " + imgNames.size());
    firstRun = false;
  }

  if (numReps < numRepsMax) {
    alphaImg.beginDraw();  
    for (int j=0; j<numDrawerReps; j++) {
      for (int i=0; i<numDrawers; i++) {
        float x = noise(0.01*frameCount+i)*width*2-width/2;
        float y = noise(0.01*frameCount+30*i)*height*2-height/2;
        int index = constrain(int(x) + int(y) * img.width, 0, img.pixels.length-1);
        //important--first check if there's anything there
        //color c = color(img.pixels[index], 127);
        color c = img.pixels[index];
        if (alpha(c) != 0) {
          //c = color(c,127);
          float theta = map(brightness(c), 0, 255, 0, TWO_PI);
          alphaImg.pushMatrix();
          alphaImg.translate(x, y);
          alphaImg.rotate(theta);
          float bs;
          if (random(1)<leakRandom) {
            bs = random(brushSize, brushSizeMax);
          } else {
            bs = brushSize;
          }
          if (j==0) {
            //centered on first pass
            p.x=0;
            p.y=0;
          } else {
            //pick a direction on second pass;
            p.x = random(-scatter, scatter)*j;
            p.y = random(-scatter, scatter)*j;
          }
          PVector strokeDir;
          float r = random(1);
          if (r <= 0.25) {
            strokeDir = new PVector(-1, -1);
          } else if (r > 0.25 && r <= 0.5) {
            strokeDir = new PVector(-1, 1);
          } else if (r > 0.5 && r <= 0.75) {
            strokeDir = new PVector(1, -1);
          } else {
            strokeDir = new PVector(1, 1);
          }
          for (int l=0; l<numStrokes; l++) {
            doBrushSimple(new PVector(p.x + (strokeDir.x * l), p.y + (strokeDir.y * l)), c, bs);//line(0, 0, 0, random(5, 15));
          }

          alphaImg.popMatrix();
        }
      }
    }
    alphaImg.endDraw();
    image(alphaImg, 0, 0);
    if (numReps > (numRepsMax/2) && brushSize > brushSizeMin) brushSize *= shrinkAmount;
    numReps++;
  } else {
    if (cleanOutlines) {  
      //uses the alpha of the original image 
      color c1, c2;
      alphaImg.loadPixels();
      alphaImgOrig.loadPixels();
      for (int i=0; i<alphaImg.pixels.length; i++) {
        c1 = alphaImg.pixels[i];
        c2 = alphaImgOrig.pixels[i];
        float r = red(c1);
        float g = green(c1);
        float b = blue(c1);
        float a = alpha(c2);
        alphaImg.pixels[i] = color(r, g, b, a);
      }
      alphaImg.updatePixels();
    }
    if (counter<imgNames.size()-1) {
      saveGraphics(alphaImg, false); //don't exit
      counter++;
      numReps = 0;
      brushSize = brushSizeOrig;
      nextImage(counter);
      prepGraphics();
    } else {
      saveGraphics(alphaImg, true); //exit
    }
  }
}

void prepGraphics() {
  background(0);
  alphaImg = createGraphics(width, height, JAVA2D);
  alphaImg.beginDraw();  
  // make sure alpha is set to 0--may no longer be needed in Processing 2
  alphaImg.loadPixels();
  for (int i=0; i<alphaImg.pixels.length; i++) {
    alphaImg.pixels[i] = color(0, 0);
  }
  alphaImg.updatePixels();    
  if (useBase) alphaImg.image(img, 0, 0); //build on original image
  alphaImg.endDraw();

  alphaImgOrig = createGraphics(width, height, JAVA2D);  
  alphaImgOrig.beginDraw();
  alphaImgOrig.loadPixels();
  for (int i=0; i<alphaImgOrig.pixels.length; i++) {
    alphaImgOrig.pixels[i] = color(0, 0);
  }
  alphaImgOrig.updatePixels();  
  alphaImgOrig.image(img, 0, 0);
  alphaImgOrig.endDraw();
}

void doBrushSimple(PVector p, color c, float _bs) {
  float r = red(c);
  float g = green(c);
  float b = blue(c);
  float a = alpha(c) - alphaDecrease;
  if (a<0) a=0;
  alphaImg.tint(color(r, g, b, a));
  alphaImg.imageMode(CENTER);
  alphaImg.image(brush, p.x, p.y, _bs, _bs);
}