#include <Arduino.h>
#include "camera.h"
#include "wire.h"
#include "ArduinoBLE.h"
/*-----Uncomment the library and class for your specific hardware-----*/
//#include "himax.h"  // API to read from the Himax camera found on the Portenta Vision Shield Rev.1
//HM01B0 himax;

#include "himax.h" // API to read from the Himax camera found on the Portenta Vision Shield Rev.2
HM01B0 himax;

Camera cam(himax);
#define IMAGE_MODE CAMERA_GRAYSCALE
FrameBuffer fb(320,240,2);

unsigned long lastUpdate = 0;

//lets right some BLE code
// helpfull arduino DOC: https://docs.arduino.cc/tutorials/portenta-h7/ble-connectivity/
BLEService ledService("19b10000-e8f2-537e-4f6c-d104768a1214");
BLEByteCharacteristic switchCharacteristic("19b10000-e8f2-537e-4f6c-d104768a1214", BLERead | BLEWrite);


void setup() {
  Serial.begin(250000);
  //Init the cam QVGA, 30FPS
  cam.begin(CAMERA_R320x240, IMAGE_MODE, 30);
  //begin the BLE
  if(!BLE.begin()){
    while(1){
      Serial.println("starting BLE failed!");
      delay(1000);
    }
  }
    // don't continue
    //set the name and the service
  BLE.setLocalName("LED-Portenta-01");
  BLE.setAdvertisedService(ledService);
  // Add the characteristic to the service
  ledService.addCharacteristic(switchCharacteristic);

  // Add service
  BLE.addService(ledService);

  // Set the initial value for the characeristic:
  switchCharacteristic.writeValue(0);

  // start advertising
  BLE.advertise();
  digitalWrite(LEDB, LOW);
  delay(1000);
  digitalWrite(LEDB, HIGH);
  Serial.println("BLE LED Control ready");

}



void loop() {
  Serial.println("Everything initialized smoothly");
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
  