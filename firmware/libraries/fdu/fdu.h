
/*
	fdu.h

*/

#ifndef FDU_H
#define FDU_H

/* FDU Functions */

//int stroke_wdt(int rti_period, int rti_width);
void setFduMode(int val);
int getFduMode(void);
void stroke_wdt(void* p);
void gen_alive(void* p);
void error_injector(void* p);
void setPrime(int i);
int isPrime(void);
void run_away_callback(int id);
void run_away (void *p);
/* OSC Interface */
const char* fduOsc_GetName( void );
int fduOsc_ReceiveMessage( int channel, char* message, int length );

#endif
