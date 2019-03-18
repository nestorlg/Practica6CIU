import java.lang.*;
import processing.video.*;
import cvimage.*;
import org.opencv.core.*;
//Detectores
import org.opencv.objdetect.CascadeClassifier;
import org.opencv.objdetect.Objdetect;
import processing.sound.*;

Capture cam;
CVImage img;
PImage trump;
SoundFile wall;
int mode;
float newR, newG, newB;
ArrayList <Polygon> polygons;

//Cascadas para detección
CascadeClassifier face,leye,reye;
//Nombres de modelos
String faceFile, leyeFile,reyeFile;
color oldPixelColour;
color updatedPixelColour;

void setup() {
  size(640, 480);
  //Cámara
  cam = new Capture(this, width , height);
  cam.start(); 
  
  //OpenCV
  //Carga biblioteca core de OpenCV
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  println(Core.VERSION);
  img = new CVImage(cam.width, cam.height);
  
  //Detectores
  faceFile = "haarcascade_frontalface_default.xml";
  leyeFile = "haarcascade_mcs_lefteye.xml";
  reyeFile = "haarcascade_mcs_righteye.xml";
  face = new CascadeClassifier(dataPath(faceFile));
  leye = new CascadeClassifier(dataPath(leyeFile));
  reye = new CascadeClassifier(dataPath(reyeFile));
  trump = loadImage("trump.jpg");
  wall = new SoundFile(this,"wall.mp3");
  
  PShape star = createShape();
  star.beginShape();
  star.noStroke();
  star.fill(128,64,128);
  star.vertex(0,-50);
  star.vertex(14,-20);
  star.vertex(47,-15);
  star.vertex(23,7);
  star.vertex(29,40);
  star.vertex(0,25);
  star.vertex(-29,40);
  star.vertex(-23,7);
  star.vertex(-47,-15);
  star.vertex(-14,-20);
  polygons = new ArrayList<Polygon>();
  for (int i = 0;i < 25;i++) {
    polygons.add(new Polygon(star));
  }
  
  mode = 0;
}

void draw() {
  //System.out.println(mode);
  switch (mode) {
    case 0:
            if (cam.available()) {
              background(0);
              cam.read();
    
              //comportamiento diferenciado si hay clic
              if (mousePressed)
                //Desplaza la imagen de forma aleatoria al mostrarla
                image(cam,random(-5,5),random(-5,5));
              else
                image(cam,0,0);
            }
            break;
    case 1:
            if (cam.available()) {
              background(0);
              cam.read();
    
              //Obtiene la imagen de la cámara
              img.copy(cam, 0, 0, cam.width, cam.height, 
              0, 0, img.width, img.height);
              img.copyTo();
    
              //Imagen de grises
              Mat gris = img.getGrey();
    
              //Copia de Mat a CVImage
              cpMat2CVImage(gris,img);
    
              //Visualiza ambas imágenes
              image(img,0,0);
    
              //Libera
              gris.release();
            }
            break;
    case 2:
            if (cam.available()) {
              background(0);
              cam.read();
    
              //comportamiento diferenciado si hay clic
              if (mousePressed)
                //Desplaza la imagen de forma aleatoria al mostrarla
                image(cam,random(-5,5),random(-5,5));
              else
                image(cam,0,0);
            }
            for (Polygon poly: polygons) {
              poly.display();
              poly.move();
            }
            break;
    case 3:
            if (cam.available()) {
              background(0);
              cam.read();
    
              //Obtiene la imagen de la cámara
              img.copy(cam, 0, 0, cam.width, cam.height, 
              0, 0, img.width, img.height);
              img.copyTo();
    
              //Imagen de grises
              Mat gris = img.getGrey();
    
              //Imagen de entrada
              image(img,0,0);
    
              //Detección y pintado de contenedores
              FaceDetect(gris);
    
              gris.release();
            }
            break;
    default:
            if (cam.available()) {
              background(0);
              cam.read();
    
              //comportamiento diferenciado si hay clic
              if (mousePressed)
                //Desplaza la imagen de forma aleatoria al mostrarla
                image(cam,random(-5,5),random(-5,5));
              else
                image(cam,0,0);
            }
            break;      
  }
  
}


void FaceDetect(Mat grey)
{
  Mat auxroi;
  
  //Detección de rostros
  MatOfRect faces = new MatOfRect();
  face.detectMultiScale(grey, faces, 1.15, 3, Objdetect.CASCADE_SCALE_IMAGE, new Size(60, 60), new Size(200, 200));
  Rect [] facesArr = faces.toArray();
   //Dibuja contenedores
  noFill();
  stroke(255,0,0);
  strokeWeight(4);
  if (mode == 3) {
    for (Rect r : facesArr) {  
      image(trump,r.x,r.y, r.width, r.height);
    }
  }
  faces.release();
}

void  cpMat2CVImage(Mat in_mat,CVImage out_img)
{    
  byte[] data8 = new byte[cam.width*cam.height];
  
  out_img.loadPixels();
  in_mat.get(0, 0, data8);
  
  // Cada columna
  for (int x = 0; x < cam.width; x++) {
    // Cada fila
    for (int y = 0; y < cam.height; y++) {
      // Posición en el vector 1D
      int loc = x + y * cam.width;
      //Conversión del valor a unsigned basado en 
      //https://stackoverflow.com/questions/4266756/can-we-make-unsigned-byte-in-java
      int val = data8[loc] & 0xFF;
      //Copia a CVImage
      out_img.pixels[loc] = color(val);
    }
  }
  out_img.updatePixels();
}

void mousePressed() {
  if (mode == 3) thread("reproducir");
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      mode--;
      if (mode < 0) mode = 3;
    } else {
      if (keyCode == RIGHT) {
        mode++;
        if (mode > 3) mode = 0;
      }
    }
  }
}

void reproducir() {
  wall.play();
}

class Polygon {
  PShape s;
  float x,y;
  float speed;
  
  Polygon(PShape s_) {
    x = random(width);
    y = random(-500, -100);
    s = s_;
    speed = random(2,6);
  }
  
  void move() {
    y += speed;
    if (y > height + 100) {
      y = -100;
    }
  }
  
  void display() {
    pushMatrix();
      translate(x,y);
      shape(s);
    popMatrix();
  }
}
