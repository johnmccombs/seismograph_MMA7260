/*

  Graphs the output of a Freescale MMA7260 micromachined accelerometer. The
  graph is displayed on a ST7565 128x64 LCD.

  Records the output of the accelerometer for a period (e.g. 60s) of time and 
  graphs the max value for that period.
    
  This project was built as a simple seismograph.

  The accelerometer is wired to analog 0,1,2 for x,y,z respectively. The 
  sensitivity is set to 1.5G by wiring g-Select1 & 2 to gnd.
  
  The LCD is wired to digital pins 9, 8, 7, 6, 5 for SID, SCLK, A0, RST, CS.

--
Copyright (C) 2010 by Integrated Mapping Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/


// import the lcd library
#include "ST7565.h"

// initialize the library with the numbers of the interface pins
// SID, SCLK, A0, RST, CS
ST7565 glcd(9, 8, 7, 6, 5);

// stores the zero reference values
int y0, x0, z0; 

// number of second between graph updates. 60 seconds give just over 2 hrs
// across the this display
#define updatePeriod 5

// number of 
unsigned long readingsInPeriod;

// max accelerometer magnitude for the period
int maxForPeriod = 0;

// used to sum accelerometer output for each period. used
// to computer the average for the period
unsigned long xTot, yTot, zTot; 

// x,y values from the previous point on the graph
int lastX = 0; 
int lastY = 0;

unsigned long elapsedTime;

// number of updates of the LCD, i.e. pixels in the x direction
long ct = 0;

// analog pins to read the accelerometer
#define pinX 0
#define pinY 1
#define pinZ 2


/* ------------------------------------------------------------------------------------------------------ */
void setup()
{

  // init the reference variables
  x0 = analogRead(0);       // read analog input pin 0
  y0 = analogRead(1);       // read analog input pin 1
  z0 = analogRead(2);       // read analog input pin 2

  readingsInPeriod = 0;
  elapsedTime = millis();

  // init the LCD
  glcd.st7565_init();
  glcd.st7565_command(CMD_DISPLAY_ON);
  glcd.st7565_command(CMD_SET_ALLPTS_NORMAL);
  glcd.st7565_set_brightness(0x15);

  glcd.clear();
  glcd.display(); 
  

}



/* ------------------------------------------------------------------------------------------------------ */
void loop() 
{
  int x, y, z;
  int x1, y1, z1;
  
  // read the x,y,z accelerometer values. 
  x = analogRead(pinX);       
  y = analogRead(pinY);       
  z = analogRead(pinZ);       
  
  // total the readings
  readingsInPeriod++;
  xTot += x;
  yTot += y;
  zTot += z;

  // subtract the reference reading
  x1 = x - x0;
  y1 = y - y0;
  z1 = z - z0;

  // calcuate the magnitude of the acceleration vector
  float m = sqrt(x1*x1 + y1*y1 + z1*z1) * 2; 
  
  // store the max value
  if (m > maxForPeriod)
    maxForPeriod = m;
  
  // has the update period elapsed (millis wrap around is ignored) 
  if (millis() - elapsedTime > (updatePeriod * 1000L)) {

    // count the screen updates, after we reach the right edge of the scren, clear it.
    ct++;
    if (ct > 127) {
      ct = 0;
      lastX = 0;
      glcd.clear();
    }
  
  
    // plot the raw accelerometer magnitude in the y direction of the LCD
    // and clamp to a max of 63 (y pixels)
    int iY = int(maxForPeriod);
    if (iY > 63)
      iY = 63;
      
    // the x value is the number of updates
    int iX = ct;
  
    // draw the acceleration value
    glcd.drawline(lastX, lastY, iX, iY, BLACK);
    
    // remember the last value
    lastX = iX;
    lastY = iY;
  
    // display the max value for the period - sprintf can't do floats
    char buf[50];
    int temp1 = (maxForPeriod - (int)maxForPeriod) * 100;
    sprintf(buf, "%d.%d      ", int(maxForPeriod), temp1);
    glcd.drawstring(0,0, buf);
    glcd.display();
  
    // reset the value and timer
    elapsedTime = millis();
    maxForPeriod = 0; 

    // recalc the zero
    rezero(&xTot, &yTot, &zTot, &readingsInPeriod);
    
  }
  


}


/* ------------------------------------------------------------------------------------------------------ */
void rezero(unsigned long *x, unsigned long *y, unsigned long *z, unsigned long *readingsInPeriod) {
  
  // this routine recalculates the reference readings for the accelerometer as the
  // average of all readings for the period.
  
  x0 = *x / *readingsInPeriod;
  y0 = *y / *readingsInPeriod;
  z0 = *z / *readingsInPeriod;
  
  *x = 0;
  *y = 0;
  *z = 0;
  *readingsInPeriod = 0;
  
}




