#include <Arduino.h>
#include "ArduinoBLE.h"
//Adafruit_BNO055 bno = Adafruit_BNO055(55);
/*-----Uncomment the library and class for your specific hardware-----*/
//#include "himax.h"  // API to read from the Himax camera found on the Portenta Vision Shield Rev.1
//HM01B0 himax;

#include "himax.h" // API to read from the Himax camera found on the Portenta Vision Shield Rev.2
HM01B0 himax;
bool scanning = false;
Camera cam(himax);
#define IMAGE_MODE CAMERA_GRAYSCALE
FrameBuffer fb(320,240,2);

unsigned long lastUpdate = 0;
uint8_t packet[25];
BLEDevice esp32; 
//lets right some BLE code
// helpfull arduino DOC: https://docs.arduino.cc/tutorials/portenta-h7/ble-connectivity/
BLEService androidService("19b10000-e8f2-537e-4f6c-d104768a1214");
BLECharacteristic androidCharacteristic(
  "19b10001-e8f2-537e-4f6c-d104768a1214",
  BLERead | BLENotify,
  27    // max length in bytes
);

void central() {

  if (!esp32 || !esp32.connected()) {
    esp32 = BLE.available();
    if (esp32 && esp32.localName() == "ESP32PERFECTPUTT") {
      BLE.stopScan();
      scanning = false;
      if (esp32.connect()) {
        esp32.discoverAttributes();
      }
    } else {

      if(!scanning){
        BLE.scan(); 
        scanning = true;
      }
    }
  } else {

    BLECharacteristic myChar = esp32.characteristic("d8450001-6421-4f80-928d-19548483b890");
    if (myChar && myChar.canRead()) {
      myChar.readValue(packet, 25); 
      Serial.print(packet[3]);
    }
    else {

      esp32.discoverAttributes();
    }
  }
}
void peripheral() {
  BLEDevice central = BLE.central();

  if (central && central.connected()) {

    androidCharacteristic.writeValue(packet, 25);
  }

  bool timeoutDetected = (millis() - lastUpdate > 2000);

  lastUpdate = millis();
}
void setup() {
  Serial.begin(250000);

  cam.begin(CAMERA_R320x240, IMAGE_MODE, 30);

  if(!BLE.begin()){
    while(1){
      Serial.println("starting BLE failed!");
      delay(1000);
    }
  }
  BLE.setLocalName("PerfectPuttPortenta");
  BLE.setAdvertisedService(androidService); // add the service UUID
  androidService.addCharacteristic(androidCharacteristic); // add the android characteristic
  BLE.addService(androidService); // Add the battery service

  // Start advertising
  BLE.advertise();

  BLE.scan();

}



void loop() {
  static bool Receive = true;
  static uint8_t frameID = 0;
   // Grab frame and write to serial
   /*
  if (cam.grabFrame(fb, 3000) == 0) {
    Serial.write(fb.getBuffer(), cam.frameSize());
  }*/
  /*
  //lets construct our BLE data
  uint8_t packet[15];
  packet[0] = 0x00; //protocol byte
  packet[1] = 0x01; // high byte x acceleration
  packet[2] = 0x02; // low byte x acceleration
  packet[3] = 0x03; // High byte y acceleration
  packet[4] = 0x04; // low byte y acceleration
  packet[5] = 0x05; // high byte z acceleration
  packet[6] = 0x06; // low byte z acceleration
  packet[7] = 0x07; // high byte gyro x acceleration
  packet[8] = 0x08; // low byte gyro x acceleration
  packet[9] = 0x09; // high byte gyro y acceleration
  packet[10] = 0x0A; // low byte gyro y acceleration
  packet[11] = 0x0B; // high byte gyro z acceleration
  packet[12] = 0x0C; // low byte gyro z acceleration
  packet[13] = 0x0D; // FSR 1
  packet[14] = 0x0E; // FSR 2
  */
  // Listen for Bluetooth® Low Energy peripherals to connect:
  // connect to the ESP32

  central();
  peripheral();

  
}
  