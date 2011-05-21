
// display acceleration in the y axis
// include the library code: MMA 7260
#include "ST7565.h"

// initialize the library with the numbers of the interface pins
ST7565 glcd(9, 8, 7, 6, 5);

int y0, x0, z0; 

unsigned long xTot, yTot, zTot, readingsInPeriod;


int lastX = 0; 
int lastY = 0;

long elapsedTime, ct = 0;
int callum = 0;

int graphX0 = 0;
int graphY0 = 9;
int graphyYc = graphY0 + (64-graphY0)/2;


void setup()
{
  Serial.begin(9600);           // sets the serial port to 9600

  x0 = analogRead(0);       // read analog input pin 0
  y0 = analogRead(1);       // read analog input pin 1
  z0 = analogRead(2);       // read analog input pin 2

  readingsInPeriod = 0;

  glcd.st7565_init();
  glcd.st7565_command(CMD_DISPLAY_ON);
  glcd.st7565_command(CMD_SET_ALLPTS_NORMAL);
  glcd.st7565_set_brightness(0x15);

  glcd.clear();
  glcd.display(); 
  

}




void loop() 
{
  int x, y, z;
  int x1, y1, z1;
  
  analogRead(0);
  delay(5);
  x = analogRead(0);       // read analog input pin 0

  analogRead(1);       // read analog input pin 1
  delay(5);
  y = analogRead(1);       // read analog input pin 1

  analogRead(2);       // read analog input pin 1
  delay(5);
  z = analogRead(2);       // read analog input pin 1
  
  // total the readings
  readingsInPeriod++;
  xTot += x;
  yTot += y;
  zTot += z;

//  Serial.print(x, DEC);    // print the acceleration in the X axis
//  Serial.print(" ");       // prints a space between the numbers
//  Serial.print(y, DEC);    // print the acceleration in the Y axis
//  Serial.print(" ");       // prints a space between the numbers
//  Serial.print(z, DEC);  // print the acceleration in the Z axis

  x1 = x - x0;
  y1 = y - y0;
  z1 = z - z0;

  float t = sqrt(x1*x1 + y1*y1 + z1*z1) * 2;

//  Serial.print(" ");       // prints a space between the numbers
//  Serial.println(t, DEC);  // print the acceleration in the Z axis


  char buf[50];
 
  
  if (t > callum)
    callum = t;
  
  // update the graph every 12 mins - all day to update
  if (millis() - elapsedTime > 5000) {

    ct++;
    if (ct > 127) {
      ct = 0;
      lastX = 0;
      glcd.clear();
    }
  
  
    int iY = int(callum);
    if (iY > 63)
      iY = 63;
      
    int iX = ct;
  
    // draw the acceleration value, then refresh the axis
    glcd.drawline(lastX, lastY, iX, iY, BLACK);
    
    lastX = iX;
    lastY = iY;
  
    int temp1 = (t - (int)t) * 100;
    sprintf(buf, "%d.%d      ", int(t), temp1);
    glcd.drawstring(0,0, buf);
    glcd.display();
  
    elapsedTime = millis();
    callum = 0; 

    // recalc the zero
    rezero(&xTot, &yTot, &zTot, &readingsInPeriod);
    
  }
  


}


void rezero(unsigned long *x, unsigned long *y, unsigned long *z, unsigned long *readingsInPeriod) {
  

  x0 = *x / *readingsInPeriod;
  y0 = *y / *readingsInPeriod;
  z0 = *z / *readingsInPeriod;
  
  *x = 0;
  *y = 0;
  *z = 0;
  *readingsInPeriod = 0;
  
}



void MMA7260QMMA7260Qes() {

  int tickLen;
  
  // y = 0
  glcd.drawline(0, graphyYc, 127, graphyYc, BLACK);  
  
  // 5 degree ticks.  10 degree ticks are longer
  for (int i = -30; i < 26; i+=5) {
    
    if (i % 10 == 0)
      tickLen = 3;
    else
      tickLen = 1;
    
    glcd.drawline(0, graphyYc-i, tickLen, graphyYc-i, BLACK);  
  
  }
}

