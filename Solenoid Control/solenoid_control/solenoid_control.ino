int inval = 0;
void setup() {
  // put your setup code here, to run once:
  pinMode(25,OUTPUT);
  digitalWrite(solenoidPin, LOW);
  Serial.begin(9600);
}

void loop() {
  // put your main code here, to run repeatedly:
  //Values passed to ESP32 must be in range of 0-20
  if(Serial.available()>0){
    inval = Serial.parseInt();
    inval = map(inval, 0, 20, 0, 255);
    digitalWrite(25,inval);
  }
}
