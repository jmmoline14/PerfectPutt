int inval = 0;
void setup() {
  // put your setup code here, to run once:
  pinMode(23,OUTPUT);
  digitalWrite(23, HIGH);
  Serial.begin(115200);
  Serial.println("COMM STARTED");
}

void loop() {
  // put your main code here, to run repeatedly:
  //Values passed to ESP32 must be in range of 0-10
  if(Serial.available()>0){
    inval = Serial.parseInt();
    inval = map(inval, 0, 10, 255, 0);
    digitalWrite(23,inval);
    Serial.print(inval);
    delay(5000);
  }
  else{
    digitalWrite(23,HIGH);
  }
}
