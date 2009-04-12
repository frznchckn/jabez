/** \file fdu.c	
 */

#include "appled.h"
#include "digitalout.h"
#include "digitalin.h"
#include "config.h"
#include "fdu.h"
#include "led.h"


void stroke_wdt( void* p) {

  (void)p;

  unsigned char wdt_bits[3];
  wdt_bits[0] = 0;
  wdt_bits[1] = 0;
  wdt_bits[2] = 0;
  unsigned char i = 0;

  while ( true ) {
    setPrime(DigitalIn_GetValue(0));
    Led_SetState(isPrime());
    
    Sleep (125);
		
    //DigitalOut_SetValue(3, 1);
    //Sleep (1);
    //DigitalOut_SetValue(3, 0);

    for (i = 0; i < 8; i += 1) {
		
      wdt_bits[0] = (i >> 1 & 0x1) ^ (i & 0x1);
      wdt_bits[1] = (i >> 2 & 0x1) ^ (i >> 1 & 0x1);
      wdt_bits[2] = (i >> 3 & 0x1) ^ (i >> 2 & 0x1);

      AppLed_SetState(0, wdt_bits[0]);
      AppLed_SetState(1, wdt_bits[1]);
      AppLed_SetState(2, wdt_bits[2]);
      //AppLed_SetState(3, 1);

      DigitalOut_SetValue(0, wdt_bits[0]);
      DigitalOut_SetValue(1, wdt_bits[1]);
      DigitalOut_SetValue(2, wdt_bits[2]);

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

  (void)p;
  int err = 0;
  int prev_err = 0;
  while(true) {
    err = DigitalIn_GetValue(4) | 
      (DigitalIn_GetValue(5) << 1) |
      (DigitalIn_GetValue(6) << 2) |
      (DigitalIn_GetValue(7) << 3);
    
    if (err != prev_err) {
      switch(err) {
	
      case 0: 
	break;
	
      case 1:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 1");
	break;
	
      case 2:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 2");
	break;
	
      case 3:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 3");
	break;
	
      case 4:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 4");
	break;
	
      case 5:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 5");
	break;
	
      case 6:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 6");
	break;
	
      case 7:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 7");
	break;
	
      case 8:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 8");
	break;
	
      case 9:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 9");
	break;
	
      case 10:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 10");
	break;
	
      case 11:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 11");
	break;
	
      case 12:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 12");
	break;
	
      case 13:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 13");
	break;
	
      case 14:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 14");
	break;
	
      case 15:
	Debug(DEBUG_ALWAYS, "Got Error Injection Case 15");
	break;
	
      }
    }
    
    prev_err = err;
    Sleep(5);
  }
}
