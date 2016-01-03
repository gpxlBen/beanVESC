// BeanVesc
// by Ben Harraway - http://www.gourmetpixel.com
// A simple demonsration for the VESC and LightBlue Bean by Punch Through Design
// This sketch looks for serial input on BLE and transmits to a Software Serial UART
// VESC connected to D0 and D1 (NOT A0 and A1!)

#include <SoftwareSerial.h>

SoftwareSerial softSerial(1, 0); // RX pin, TX pin on Bean

void setup() 
{   
  Serial.begin(9600); 
  softSerial.begin(9600);
} 

void loop() 
{    
      if (Serial.available()) {
        softSerial.write(Serial.read());                 
      }

      if (softSerial.available()) {
        Serial.write(softSerial.read());                 
      }


}
