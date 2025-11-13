#include "camera.h"

/*-----Uncomment the library and class for your specific hardware-----*/
//#include "himax.h"  // API to read from the Himax camera found on the Portenta Vision Shield Rev.1
//HM01B0 himax;

#include "hm0360.h" // API to read from the Himax camera found on the Portenta Vision Shield Rev.2
HM0360 himax;

Camera cam(himax);
#define IMAGE_MODE CAMERA_GRAYSCALE
FrameBuffer fb(320,240,2);

unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(250000);
  //Init the cam QVGA, 30FPS
  cam.begin(CAMERA_R320x240, IMAGE_MODE, 30);
}

void loop() {
  // put your main code here, to run repeatedly:
  if(!Serial) {    
    Serial.begin(250000);
    while(!Serial);
  }
  
  // Time out after 2 seconds and send new data
  bool timeoutDetected = millis() - lastUpdate > 2000;

  // Wait until the receiver acknowledges
  // that they are ready to receive new data
  if(!timeoutDetected && Serial.read() != 1) return;

  lastUpdate = millis();
  
  // Grab frame and write to serial
  if (cam.grabFrame(fb, 3000) == 0) {
    Serial.write(fb.getBuffer(), cam.frameSize());
  }
}