#include "Arduino.h"
#include <Wire.h>
#define CAMERA_I2C_ADDRESS 0x48   //update with real addresses later
#define LED_BUILTIN 13 
#define IMU_I2C_ADDRESS 0x68



void setup(){
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, LOW);
}


void loop(){
    digitalWrite(LED_BUILTIN, LOW);
    delay (1000);
    digitalWrite(LED_BUILTIN, HIGH);
    delay (1000);
}
// above is a blinking example, below is real I2C code
/*
void setup(){
    Wire.begin();


}
void loop(){
    uint8_t reg = 0x00;
    Wire.beginTransmission(CAMERA_I2C_ADDRESS);
    Wire.write(reg);
    Wire.endTransmission();

    delay(1000);

    Wire.beginTransmission(IMU_I2C_ADDRESS);
    Wire.write(reg);
    Wire.endTransmission();



    delay(1000);
}


*/




