// http://forum.processing.org/one/topic/help-starting-bitmap-trace.html
// brush path code by Amnon Owed

PImage img;

int numDrawers = 500; //points drawn per frame--use lots
int numDrawerReps = 2;//scattered points per point--use sparingly
int numRepsMax = 100; // draw loops--to taste
int numReps = 0;
boolean ready = false;
String brushFile = "brush2.png";
PImage brush;
int brushSize = 18;
int brushSizeMin = 5;
int brushSizeMax = 42;
float brushRandom = 2;
float leakRandom = 0.2; //0-1
float brushScatter = 4;
PGraphics alphaImg;
PGraphics alphaImgOrig;
boolean firstRun = true;
boolean cleanOutlines = true;
boolean useBase = true;

int counter = 0;

void setup() {
  //Settings settings = new Settings("settings.txt");
  loadFiles();
  nextImage(counter);
  size(img.width,img.height);
  
  brush = loadImage(brushFile);
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
        color c = color(img.pixels[index], 127);
        float theta = map(brightness(c), 0, 255, 0, TWO_PI);
        alphaImg.pushMatrix();
        alphaImg.translate(x, y);
        alphaImg.rotate(theta);
     float bs;
     if (random(1)<leakRandom) {
         bs = random(brushSizeMin,brushSizeMax);
      } else {
         bs = brushSize;
      }
        //alphaImg.stroke(c);
        //alphaImg.line(0, 0, 0, random(5, 15));
        doBrush(new PVector(0, 0), c, bs, false);//line(0, 0, 0, random(5, 15));
        alphaImg.popMatrix();
      }
    }
    alphaImg.endDraw();
    image(alphaImg,0,0);
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
        alphaImg.pixels[i] = color(r,g,b,a);
      }
      alphaImg.updatePixels();       
    }
    if (counter<imgNames.size()-1) {
      saveGraphics(alphaImg,false); //don't exit
      counter++;
      numReps = 0;
      nextImage(counter);
      prepGraphics();
    } else {
      saveGraphics(alphaImg,true); //exit
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
    alphaImgOrig.image(img,0,0);
    alphaImgOrig.endDraw();
}

void doBrush(PVector p, color c, float _b, boolean scatter) {
  alphaImg.tint(c);
  alphaImg.imageMode(CENTER);
  alphaImg.image(brush, 0, 0, _b, _b);
}

