/*
	make.c
	
	make.c is the main project file.  The Run( ) task gets called on bootup, so stick any initialization stuff in there.
	In Heavy, by default we set the USB, OSC, and Network systems active, but you don't need to if you aren't using them.
	Furthermore, only register the OSC subsystems you need - by default, we register all of them.
*/

#include "config.h"

// include all the libraries we're using
#include "appled.h"
#include "can.h"
#include "fdu.h"
/*#include "dipswitch.h"
#include "servo.h"
#include "digitalout.h"
#include "digitalin.h"
#include "motor.h"
#include "pwmout.h"
#include "stepper.h"
//#include "xbee.h"
//#include "webserver.h"
*/
#include <stdarg.h>

void CanSendTask( void* parameters );
void DebugQueueTask( void* p );
unsigned int Debug2( int level, char* format);
unsigned int init_debug_queue();

void Run( ) // this task gets called as soon as we boot up.
{
  TaskCreate( stroke_wdt, "stroke", 400, 0, 1);
  gen_alive(0);

  // Do this right quick after booting up - otherwise we won't be recognised
  Usb_SetActive( 0 );

  // Fire up the OSC system and register the subsystems you want to use
  Osc_SetActive( true, true, true, true );
  // make sure OSC_SUBSYSTEM_COUNT (osc.h) is large enough to accomodate them all
  ///Osc_RegisterSubsystem( AppLedOsc_GetName(), AppLedOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( DipSwitchOsc_GetName(), DipSwitchOsc_ReceiveMessage, DipSwitchOsc_Async );
  //Osc_RegisterSubsystem( ServoOsc_GetName(), ServoOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( AnalogInOsc_GetName(), AnalogInOsc_ReceiveMessage, AnalogInOsc_Async );
  ///Osc_RegisterSubsystem( DigitalOutOsc_GetName(), DigitalOutOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( DigitalInOsc_GetName(), DigitalInOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( MotorOsc_GetName(), MotorOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( PwmOutOsc_GetName(), PwmOutOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( LedOsc_GetName(), LedOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( DebugOsc_GetName(), DebugOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( SystemOsc_GetName(), SystemOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( NetworkOsc_GetName(), NetworkOsc_ReceiveMessage, NULL );
  //Osc_RegisterSubsystem( SerialOsc_GetName(), SerialOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( IoOsc_GetName(), IoOsc_ReceiveMessage, NULL );
  ///Osc_RegisterSubsystem( StepperOsc_GetName(), StepperOsc_ReceiveMessage, NULL );
  //Osc_RegisterSubsystem( XBeeOsc_GetName(), XBeeOsc_ReceiveMessage, XBeeOsc_Async );
  //Osc_RegisterSubsystem( XBeeConfigOsc_GetName(), XBeeConfigOsc_ReceiveMessage, NULL );
  //Osc_RegisterSubsystem( WebServerOsc_GetName(), WebServerOsc_ReceiveMessage, NULL );
  
  

  AppLed_SetState(0, 1);
  
  // Starts the network up.  Will not return until a network is found...
  //Network_SetDhcpEnabled(1);
  //Network_SetActive( true );
  
  AppLed_SetState(1, 1);

  //init_debug_queue();
  //TaskCreate( DebugQueueTask, "debugqueue", 400, 0, 1);
  AppLed_SetState(2, 1);
  Can_SetActive(1);
  Can_InitReceive();
  TaskCreate( CanSendTask, "canSend", 400, 0, 1);
  
  /*
  AppLed_SetState(2, Network_GetActive());

  {
    int a0, a1, a2, a3;
    Network_GetAddress(&a0, &a1, &a2, &a3);
    if (a0 == 137) {
      AppLed_SetState(3, 1);
    }
  }*/
}


void CanSendTask( void* p )
{
 (void)p;

 Frame frame;
  
  frame.standard = 1;
  frame.identifier1 = 0x7FF;
  frame.rtr = 0;
  frame.dlc = 8;
  frame.data[0] = 0x01;
  frame.data[1] = 0x23;
  frame.data[2] = 0x45;
  frame.data[3] = 0x67;
  frame.data[4] = 0x89;
  frame.data[5] = 0xab;
  frame.data[6] = 0xcd;
  frame.data[7] = 0xef;
  
  while(true) {
    Sleep(500);
    Can_SendData(&frame);
  }
	       
}


////////////////////////////////////////////////


////////////////////////////////////////////////////////

#define QUEUE_DEPTH 16
char** debug_queue;
#define DEBUG_MAX_MESSAGE 60
int debug_level_queue[QUEUE_DEPTH];
int add_pointer;
int send_pointer;
void* debugSemaphore;
int debug_queue_initialized = 0;

unsigned int init_debug_queue() {
  int i,j;
  
  debugSemaphore = SemaphoreCreate();
  
  if (SemaphoreTake( debugSemaphore, 1000 )) {
    add_pointer = 0;
    send_pointer = 0;
    debug_queue = (char**) MallocWait(sizeof(char*) * (QUEUE_DEPTH * 2), 1000);
    for(i = 0; i < QUEUE_DEPTH * 2; i++) {
      debug_queue[i] = (char*) MallocWait(sizeof(char) * (DEBUG_MAX_MESSAGE + 1), 1000);
      debug_level_queue[i/2] = 0;
      for(j = 0; j < DEBUG_MAX_MESSAGE + 1; j++) {
	debug_queue[i/2][j] = 0;
      }
    }
    Debug(DEBUG_ALWAYS, "Debug queue initialized");
    debug_queue_initialized = 1;
    SemaphoreGive( debugSemaphore );
  }
}

//unsigned int Debug2( int level, char* format, ... ) {
unsigned int Debug2( int level, char* format) {
  if (debug_queue_initialized == 0) {
    return 0;
  }

  strncpy(debug_queue[add_pointer], format, DEBUG_MAX_MESSAGE); 
  
  debug_level_queue[add_pointer] = level;
    
  if (add_pointer == QUEUE_DEPTH - 1) {
    add_pointer = 0;
  } else {
    add_pointer++;
  }
  
}

void DebugQueueTask( void* p ) {
  (void)p;
  char* string;
  int level = 0;
  int have_message = 0;
  
  if (debug_queue_initialized == 0) {
    return 0;
  }
  string = Malloc(sizeof(char) * DEBUG_MAX_MESSAGE);
  string[0] = 0;
  AppLed_SetState(3, 1);
  
  while ( true ) {
    have_message = 0;
    
    Sleep(5);
    Led_SetState(!Led_GetState());
    
    if (add_pointer != send_pointer) {
      strcpy(string, debug_queue[send_pointer]);
      level = debug_level_queue[send_pointer];
      have_message = 1;
      
      if (send_pointer == QUEUE_DEPTH - 1) {
	send_pointer = 0;
      } else {
	send_pointer++;
      }
    }
    
    if (have_message) {
      Debug(level, string);
    }
    
  }
  
  
}
