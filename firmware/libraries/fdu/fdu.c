/** \file fdu.c	
 */

#include "appled.h"
#include "digitalout.h"
#include "digitalin.h"
#include "config.h"
#include "fdu.h"
#include "led.h"

//int stroke_wdt(int rti_period, int rti_width) {
int stroke_wdt( void* p) {

  (void)p;

  unsigned char count = 0;
  unsigned char wdt_bits[3];
  wdt_bits[0] = 0;
  wdt_bits[1] = 0;
  wdt_bits[2] = 0;
  unsigned char i = 0;

  //AppLed_SetState(0, 0);
  //AppLed_SetState(1, 0);
  //AppLed_SetState(2, 0);
  //AppLed_SetState(3, 0);

  while ( true ) {
    setPrime(AnalogIn_GetValue(0) > 512);
    Led_SetState(isPrime());
    
    //AppLed_SetState(0, !AppLed_GetState(0));
    Sleep (124);
		
    DigitalOut_SetValue(3, 1);
    Sleep (1);
    DigitalOut_SetValue(3, 0);

    for (i = 0; i < 8; i += 1) {
		
      wdt_bits[0] = (i >> 1 & 0x1) ^ (i & 0x1);
      wdt_bits[1] = (i >> 2 & 0x1) ^ (i >> 1 & 0x1);
      wdt_bits[2] = (i >> 3 & 0x1) ^ (i >> 2 & 0x1);

      //AppLed_SetState(0, wdt_bits[0]);
      //AppLed_SetState(1, wdt_bits[1]);
      //AppLed_SetState(2, wdt_bits[2]);
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
void aliveIRQCallback(int id) {
  (void)id;
  
  aliveValue = !aliveValue;
  if (isPrime()) {
    DigitalOut_SetValue(3, aliveValue);
  } else {
    DigitalOut_SetValue(3, 0);
  }
}

int gen_alive( void* p) {

  (void)p;

  FastTimer_SetActive(true);
  FastTimer_InitializeEntry( &aliveTimer, aliveIRQCallback, 0, 100 /*us*/, true );
  FastTimer_Set( &aliveTimer ); // start our timer
  
  return 0;

}
