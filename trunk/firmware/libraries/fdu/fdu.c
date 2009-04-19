/** \file fdu.c	
 */

#include "appled.h"
#include "digitalout.h"
#include "digitalin.h"
#include "config.h"
#include "fdu.h"
#include "led.h"

int fdu_mode = 0;
void setFduMode(int val) {
  fdu_mode = val;
}
int getFduMode() {
  return fdu_mode;
}

void stroke_wdt( void* p) {

  (void)p;

  unsigned char wdt_bits[3];
  wdt_bits[0] = 0;
  wdt_bits[1] = 0;
  wdt_bits[2] = 0;
  unsigned char i = 0;
  setFduMode(1);

  while ( true ) {
    setPrime(DigitalIn_GetValue(0));
    Led_SetState(isPrime());
    
    if (getFduMode() == 6) {
      Sleep (200);
    } else {
      Sleep (100);
    }
    
		
    //DigitalOut_SetValue(3, 1);
    //Sleep (1);
    //DigitalOut_SetValue(3, 0);

    for (i = 0; i < 8; i += 1) {
      
      if (getFduMode() != 4) {
        
        if (getFduMode() == 5) {
          //simulate out of order
          i = i - 2;
        }
        wdt_bits[0] = (i >> 1 & 0x1) ^ (i & 0x1);
        wdt_bits[1] = (i >> 2 & 0x1) ^ (i >> 1 & 0x1);
        wdt_bits[2] = (i >> 3 & 0x1) ^ (i >> 2 & 0x1);
        
        //	AppLed_SetState(0, wdt_bits[0]);
        //	AppLed_SetState(1, wdt_bits[1]);
        //	AppLed_SetState(2, wdt_bits[2]);
        //AppLed_SetState(3, 1);

        DigitalOut_SetValue(0, wdt_bits[0]);
        DigitalOut_SetValue(1, wdt_bits[1]);
        DigitalOut_SetValue(2, wdt_bits[2]); 
      }
      
    }
  }
}


///////////////////////////////////////////////////////////
int ISPRIME = 0;

int isPrime() {
  return ISPRIME;
}

void setPrime(int i) {
  ISPRIME = i;
}
///////////////////////////////////////////////////////////


FastTimerEntry aliveTimer; // our TimerEntry
int aliveValue = 0;
void aliveIRQCallback(int id);
void aliveIRQCallback(int id) {
  (void)id;
  
  aliveValue = !aliveValue;
  if (isPrime()) {
    DigitalOut_SetValue(3, aliveValue);
  } else {
    DigitalOut_SetValue(3, 0);
  }
}

void gen_alive( void* p) {

  (void)p;

  FastTimer_SetActive(true);
  FastTimer_InitializeEntry( &aliveTimer, aliveIRQCallback, 0, 100 /*us*/, true );
  FastTimer_Set( &aliveTimer ); // start our timer
  
  return;

}


///////////////////////////////////////////////////////////

void error_injector( void* p) {
  Sleep(1000);

  (void)p;
  int err = 0;
  int prev_err = 0;
  while(true) {
    err = DigitalIn_GetValue(4) | 
      (DigitalIn_GetValue(5) << 1) |
      (DigitalIn_GetValue(6) << 2) |
      (DigitalIn_GetValue(7) << 3);
   
    if (err != 0) {

      AppLed_SetState(0, (err >> 0) & 0x1);
      AppLed_SetState(1, (err >> 1) & 0x1);
      AppLed_SetState(2, (err >> 2) & 0x1);
      AppLed_SetState(3, (err >> 3) & 0x1);

      switch(err) {
	
      case 0:
        setFduMode(1);
		break;
	
      case 1:
        setFduMode(1);
        break;
	
      case 2:
        setFduMode(1);
        break;
	
      case 3:
        setFduMode(1);
        break;
	
      case 4:
        //grey code stuck
        setFduMode(4);
        break;
	
      case 5:
        //grey code out of order
        setFduMode(5);
        break;
	
      case 6:
        //grey code slow
        setFduMode(6);
        break;
	
      case 7:
        setFduMode(1);
        break;
	
      case 8:
        setFduMode(1);
        break;
	
      case 9:
        setFduMode(1);
        break;
	
      case 10:
        setFduMode(1);
        break;
	
      case 11:
        setFduMode(1);
        break;
	
      case 12:
        setFduMode(1);
        break;
	
      case 13:
        setFduMode(1);
        break;
	
      case 14:
        setFduMode(1);
        break;
	
      case 15:
        setFduMode(1);
        break;
	
      }
    }
    
    prev_err = err;
    Sleep(5);
  }
}
