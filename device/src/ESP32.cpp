#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>
#include "ArduinoBLE.h"

uint16_t BNO055_SAMPLERATE_DELAY_MS = 100;
sensors_event_t accelEvent, gyroEvent;
Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28, &Wire); // sets where the BNO055 is
uint8_t packet[25]; 
//Service UUID
BLEService IMUService("d8450000-6421-4f80-928d-19548483b890");

// Characteristic UUID
BLECharacteristic IMUCharacteristic(
  "d8450001-6421-4f80-928d-19548483b890",
  BLERead | BLENotify,
  27    // max length in bytes
);
//First FSR pin
const int FSRPINF = 36; //ADC0 on GPIO 36
void SetUpPeriph(){
  // Need to have already included BLE.
  BLE.setLocalName("ESP32PERFECTPUTT");
  BLE.setAdvertisedService(IMUService); // add the service UUID
  IMUService.addCharacteristic(IMUCharacteristic); // add the android characteristic
  BLE.addService(IMUService);

  // Start advertising
  BLE.advertise();
}
void setup() {
  Serial.begin(115200);
  Wire.begin();
  while (!Serial);
  bno.begin();
  BLE.begin();
  SetUpPeriph();
  analogReadResolution(12);        // 0–4095
  analogSetAttenuation(ADC_11db);  // allow full 0–3.3V range
}
void loop() { 
  bno.getEvent(&accelEvent, Adafruit_BNO055::VECTOR_ACCELEROMETER);
  bno.getEvent(&gyroEvent, Adafruit_BNO055::VECTOR_GYROSCOPE);

  // Get acceleration data
  float accelx = accelEvent.acceleration.x;
  float accely = accelEvent.acceleration.y;
  float accelz = accelEvent.acceleration.z;

  //get gyroscope data
  float gyrox = gyroEvent.gyro.x;
  float gyroy = gyroEvent.gyro.y;
  float gyroz = gyroEvent.gyro.z;
  packet[0] = 0x00;   // Header


  float* floatData = (float*)&packet[1];

  floatData[0] = accelEvent.acceleration.x;
  floatData[1] = accelEvent.acceleration.y;
  floatData[2] = accelEvent.acceleration.z;
  floatData[3] = gyroEvent.gyro.x;
  floatData[4] = gyroEvent.gyro.y;
  floatData[5] = gyroEvent.gyro.z;

  BLEDevice central = BLE.central();
  if(central.connected()){
    IMUCharacteristic.writeValue(packet, 25);
  }

  
  Serial.print("Acc: ");
  Serial.print(accelx, 2);  Serial.print(", ");
  Serial.print(accely, 2);  Serial.print(", ");
  Serial.print(accelz, 2);

  Serial.print(" | Gyro: ");
  Serial.print(gyrox, 2);   Serial.print(", ");
  Serial.print(gyroy, 2);   Serial.print(", ");
  Serial.println(gyroz, 2);   // newline ends the line
  

  int adc = analogRead(FSRPINF);
  float voltage = adc * (3.3 / 4095.0);

  Serial.print("Voltage: ");
  Serial.print(voltage, 3); // 3 decimal places
  Serial.println(" V");

  delay(1000);
}