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
#include "dipswitch.h"
#include "servo.h"
#include "digitalout.h"
#include "digitalin.h"
#include "motor.h"
#include "pwmout.h"
#include "stepper.h"
#include "xbee.h"
#include "webserver.h"

void BlinkTask( void* parameters );
void CountTask( void* parameters );
void CanSendTask( void* parameters );
void CanReceiveTask( void* parameters );

void Run( ) // this task gets called as soon as we boot up.
{
  //  TaskCreate( BlinkTask, "Blink", 400, 0, 1 );
  //  TaskCreate( CountTask, "Count", 400, 0, 1 );
  TaskCreate( stroke_wdt, "stroke", 400, 0, 1);

  // Do this right quick after booting up - otherwise we won't be recognised
  Usb_SetActive( 1 );

  // Fire up the OSC system and register the subsystems you want to use
  Osc_SetActive( true, true, true, true );
  // make sure OSC_SUBSYSTEM_COUNT (osc.h) is large enough to accomodate them all
  Osc_RegisterSubsystem( AppLedOsc_GetName(), AppLedOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( AppLedOsc_GetName(), AppLedOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( DipSwitchOsc_GetName(), DipSwitchOsc_ReceiveMessage, DipSwitchOsc_Async );
  Osc_RegisterSubsystem( ServoOsc_GetName(), ServoOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( AnalogInOsc_GetName(), AnalogInOsc_ReceiveMessage, AnalogInOsc_Async );
  Osc_RegisterSubsystem( DigitalOutOsc_GetName(), DigitalOutOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( DigitalInOsc_GetName(), DigitalInOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( MotorOsc_GetName(), MotorOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( PwmOutOsc_GetName(), PwmOutOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( LedOsc_GetName(), LedOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( DebugOsc_GetName(), DebugOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( SystemOsc_GetName(), SystemOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( NetworkOsc_GetName(), NetworkOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( SerialOsc_GetName(), SerialOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( IoOsc_GetName(), IoOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( StepperOsc_GetName(), StepperOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( XBeeOsc_GetName(), XBeeOsc_ReceiveMessage, XBeeOsc_Async );
  Osc_RegisterSubsystem( XBeeConfigOsc_GetName(), XBeeConfigOsc_ReceiveMessage, NULL );
  Osc_RegisterSubsystem( WebServerOsc_GetName(), WebServerOsc_ReceiveMessage, NULL );


  
  Can_SetActive(1);
  TaskCreate( CanSendTask, "canSend", 400, 0, 1);
  //TaskCreate( CanReceiveTask, "canReceive", 400, 0, 1);
  
  
  // Starts the network up.  Will not return until a network is found...
  Network_SetActive( true );
  WebServer_SetActive(1);
  

  //AppLed_SetState(0, WebServer_SetActive(1) == 0);
  //AppLed_SetState(1, WebServer_GetActive());
  //AppLed_SetState(2, WebServer_GetListenPort() == 80); 
  //AppLed_SetState(3, WebServer_GetListenPort() != 80); 

  //Led_SetState(1);
}

// A very simple task...a good starting point for programming experiments.
// If you do anything more exciting than blink the LED in this task, however,
// you may need to increase the stack allocated to it above.
void BlinkTask( void* p )
{
 (void)p;
  Led_SetState( 1 );
  Sleep( 1000 );

  while ( true )
  {
    Led_SetState( 0 );
    Sleep( 900 );
    Led_SetState( 1 );
    Sleep( 10 ); 
  }
}



void CountTask( void* p )
{
 (void)p;

 //unsigned char count = 0;

 AppLed_SetState(0, 0);
 AppLed_SetState(1, 0);
 AppLed_SetState(2, 0);
 AppLed_SetState(3, 0);
 
  while ( true ) {

    Sleep (124);
		
    
  }
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
   Sleep(2000);
   Can_SendData(frame);
 }
	       
}

void CanReceiveTask( void* p )
{
 (void)p;
 int val;
 int data[1];

 Can_ReceiveData(data);
	       
}

