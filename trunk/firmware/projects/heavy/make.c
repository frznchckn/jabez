/*
	make.c
	
	make.c is the main project file.  The Run( ) task gets called on bootup, so stick any initialization stuff in there.
	In Heavy, by default we set the USB, OSC, and Network systems active, but you don't need to if you aren't using them.
	Furthermore, only register the OSC subsystems you need - by default, we register all of them.
*/

#include "config.h"
#include "math.h"

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

#include <stdarg.h>

void CanSendTask( void* parameters );
//void DebugQueueTask( void* p );
//unsigned int Debug2( int level, char* format);
//unsigned int init_debug_queue(void);
void sendMotorCommandTask(void* p);
int sendDataMessage(unsigned int* message, int length);
void receiveMotorCommandTask(void* p);
void receiveMotorCommandEcho (char* data, int length);
unsigned int crc32 (unsigned char *block, unsigned int length);

int char2int(unsigned int* myInt, unsigned char* myChar, int lengthBytes);
int int2char(unsigned char* myChar, unsigned int* myInt, int lengthDWords);

void tellMotorBoard(unsigned int cmd, unsigned int magnitude);
void tellController(int ok);
int checkAck(unsigned int data);
int doMotorCommand(int csr, int val);

void setC0Board(int i);
void setC1Board(int i);
void setMotorBoard(int i);
void setMonitorBoard(int i);
int isMaster(void);
int isC0Board(void);
int isC1Board(void);
int isMotorBoard(void);
int isMonitorBoard(void);

void* udpsendsocket = NULL;
void* udplistensocket = NULL;

void Run( ) // this task gets called as soon as we boot up.
{
  TaskCreate( stroke_wdt, "stroke", 400, 0, 1);
  gen_alive(0);
  TaskCreate( error_injector, "errinj", 400, 0, 1);

  // Do this right quick after booting up - otherwise we won't be recognised
  Usb_SetActive( 0 );
  AppLed_SetState(0, 1);
  
  // Setup up which board this is
  setC0Board((DipSwitch_GetValue() & 3) == 0);
  setC1Board((DipSwitch_GetValue() & 3) == 1);
  setMotorBoard((DipSwitch_GetValue() & 3) == 2);
  setMonitorBoard((DipSwitch_GetValue() & 3) == 3);


  AppLed_SetState(0, isC0Board());
  AppLed_SetState(1, isC1Board());
  AppLed_SetState(2, isMotorBoard());
  AppLed_SetState(3, isMonitorBoard());
  
  // Starts the network up.  Will not return until a network is found...
  Network_SetDhcpEnabled(1);
  Network_SetActive( true );
  AppLed_SetState(1, 1);

  // calibrate the shuttle keep moving back until it trips index sensor
  if (isMotorBoard()) {
    Stepper_SetActive(1, 1);
    Stepper_SetPositionRequested(1, 100);
    int currentPos = 10;
    while (AnalogIn_GetValue(5) > 0x0100) {
      Stepper_SetPositionRequested(1, currentPos);
      while (Stepper_GetPosition(1) != currentPos) Sleep(10);
      currentPos += 2;
    }
  }


  if (isMotorBoard()) {
    Stepper_SetActive(1, 1);
    Stepper_SetPositionRequested(1, 100);
  }

  //UDP Server/Client
  while( udpsendsocket == NULL ) {
    AppLed_SetState(2, !AppLed_GetState(2));
    udpsendsocket = DatagramSocket( 0 );
    Sleep( 100 );
  }
  while( udplistensocket == NULL ) {
    AppLed_SetState(3, !AppLed_GetState(3));
    udplistensocket = DatagramSocket( 10228 );
    Sleep( 100 );
  }
  
  TaskCreate(receiveMotorCommandTask, "motorreceive", 400, 0, 1);
  if (!isMotorBoard()) {
    TaskCreate(sendMotorCommandTask, "motorsender", 400, 0, 1);
  }


  // Fire up the OSC system and register the subsystems you want to use
  /*Osc_SetActive( true, true, false, true );
  // make sure OSC_SUBSYSTEM_COUNT (osc.h) is large enough to accomodate them all
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
  */
}

int char2int(unsigned int* myInt, unsigned char* myChar, int lengthBytes) {
  int i;

  for (i = 0; i < lengthBytes; i++) {
    if (i % 4 == 0) {
      myInt[i/4] = myChar[i] << 24;
    } else if (i % 4 == 1) {
      myInt[i/4] = myInt[i/4] | (myChar[i] << 16);
    } else if (i % 4 == 2) {
      myInt[i/4] = myInt[i/4] | (myChar[i] << 8);
    } else if (i % 4 == 3) {
      myInt[i/4] = myInt[i/4] | (myChar[i] << 0);
    }
  }

  return 0;
}

int int2char(unsigned char* myChar, unsigned int* myInt, int lengthDWords) {
  int i;

  for (i = 0; i < lengthDWords; i++) {
    myChar[(i*4) + 0] = (myInt[i] >> 24) & 0xFF;
    myChar[(i*4) + 1] = (myInt[i] >> 16) & 0xFF;
    myChar[(i*4) + 2] = (myInt[i] >>  8) & 0xFF;
    myChar[(i*4) + 3] = (myInt[i] >>  0) & 0xFF;
  }

  return 0;
}

int sendDataMessage(unsigned int* message, int length) {
  int sentLength = 0;
  int* localMessageInt;
  char* localMessage;
  int i;

  localMessageInt = Malloc(sizeof(unsigned int) * (length + 1));
  localMessage = Malloc(sizeof(unsigned char) * ((length * 4) + 4));
  
  for (i = 0; i < length; i++) {
    localMessageInt[i] = message[i];
  }

  int2char(localMessage, localMessageInt, length);
  localMessageInt[length] = crc32(localMessage, length);
  int2char(localMessage, localMessageInt, length+1);
  
  if (isPrime() || isMotorBoard()) {
    sentLength = DatagramSocketSend( udpsendsocket, IP_ADDRESS( 255,255,255,255), 10228, localMessage, (length*4)+4);    
  }
  
  Free(localMessageInt);
  Free(localMessage);
  return (sentLength > 0);
}

int waiting_for_response = 0;

void sendMotorCommandTask(void* p) {
  (void)p;
  int address = IP_ADDRESS( 255,255,255,255);
  int sentLength = 0;
  char ptrn[4];
  ptrn[0] = 0xde;
  ptrn[1] = 0xad;
  ptrn[2] = 0xbe;
  ptrn[3] = 0xef;
  Debug(DEBUG_ALWAYS, "IP Address = 0x%08x", address);
  while(true) {
    int analogin[1];
    //AppLed_SetState(2, !AppLed_GetState(2));
    Sleep(1000);
    
    //sentLength = DatagramSocketSend( udpsendsocket, address, 10228, ptrn, 4 );
    //Debug(DEBUG_ALWAYS, "Sent %d bytes", sentLength); 
     
    analogin[0] = AnalogIn_GetValue(0);
    sendDataMessage(analogin, 1);

    /*    unsigned char ptrn[4];
    ptrn[0] = 0;
    ptrn[1] = 0;
    ptrn[2] = (analogIn >> 8) & 0xf;
    ptrn[3] = analogIn & 0xf;
    Sleep(1000);

    */
    //DatagramSocketClose(socket);
    //Osc_CreateMessage( OSC_CHANNEL_UDP, "/motorboard/movemoterup", ",s",  "blah");
    //Osc_SendPacket( OSC_CHANNEL_UDP );
  }
}
void receiveMotorCommandTask(void* p) {
  (void)p;
  int address, port, size;
  unsigned char* packet = Malloc(sizeof(char) * 1000);
  Debug(DEBUG_ALWAYS, "IP Address = 0x%08x", address);
  
  DigitalOut_SetValue(4, 0);
  DigitalOut_SetValue(5, 0);
  
  while(true) {
    unsigned int recv_crc32, calc_crc32;
    size = DatagramSocketReceive(udplistensocket, 10228, &address, &port, packet, 1000);
    if (size != 0) {
      unsigned int* incoming;
      unsigned int incomingSize = ceil(size / 4.0);
      incoming = Malloc(sizeof(unsigned int) * incomingSize);
      char2int(incoming, packet, size);
      AppLed_SetState(3, !AppLed_GetState(3));
      
      
      recv_crc32 = incoming[incomingSize - 1];
      calc_crc32 = crc32(packet, size - 4);
      
      if (isMonitorBoard()) {
	receiveMotorCommandEcho(packet, size);
      } else if (isMotorBoard()) {
	if (recv_crc32 == calc_crc32 && ((incoming[0] & 0x03000000) != 0) && ((incoming[0] & 0x00200000) != 0)) {
	  //AppLed_SetState(0, !AppLed_GetState(0));
	  doMotorCommand(incoming[0], incoming[1]);
	} else {
	  tellController(0);
	}
      } else if (isMaster()) {
	if (waiting_for_response) {
	  if (!checkAck(incoming[0])) {
	    //Something bad happened. Deal with it
	  }
	} else {
	  //Did not expect someone to talk. Deal with it.
	}
      }
	
      
      Free(incoming);
    }
    //DatagramSocketClose(socket);
    //Osc_CreateMessage( OSC_CHANNEL_UDP, "/motorboard/movemoterup", ",s",  "blah");
    //Osc_SendPacket( OSC_CHANNEL_UDP );
  }
}

FastTimerEntry echoTimer; // our TimerEntry
unsigned char* echoData;
int echoLengthInBytes = 0;
int echoBitPointer = 0;
int echoBytePointer = 0;
int echoRunning = 0;
void receiveMotorCommandEchoIRQCallback(int id);
void receiveMotorCommandEchoIRQCallback(int id) {
  (void)id;

  if (echoBytePointer < echoLengthInBytes) {
    DigitalOut_SetValue(4, (echoData[echoBytePointer] >> (7-echoBitPointer)) & 0x1);
      
    DigitalOut_SetValue(5, !DigitalOut_GetValue(5));

    if (echoBitPointer == 7) {
      echoBitPointer = 0;
      echoBytePointer++;
    } else {
      echoBitPointer++;
    }
  } else {
    //DigitalOut_SetValue(4, 0);
    //DigitalOut_SetValue(5, 0);
    FastTimer_Cancel(&echoTimer);
    echoRunning = 0;
  }
}

void receiveMotorCommandEcho (char* data, int length) {  
  int i;
  
  echoData = Malloc(sizeof(unsigned char) * length);
  for (i = 0; i < length; i++) {
    echoData[i] = data[i];
  }
  echoLengthInBytes = length;

  echoRunning = 1;
  echoBitPointer = 0;
  echoBytePointer = 0;

  FastTimer_SetActive(true);
  FastTimer_InitializeEntry( &echoTimer, receiveMotorCommandEchoIRQCallback, 0, 10 /*us*/, true );
  FastTimer_Set( &echoTimer ); // start our timer
  
  while(echoRunning) {
    Sleep(1);
  }
}


void crc32_gentab(void);
unsigned int crc_tab[256];
int crc_tab_generated = 0;
unsigned int crc32 (unsigned char *block, unsigned int length) {
   register unsigned long crc;
   unsigned long i;

   if (!crc_tab_generated) {
     crc32_gentab();
     crc_tab_generated = 1;
   }
   
   crc = 0xFFFFFFFF;
   for (i = 0; i < length; i++)
   {
      crc = ((crc >> 8) & 0x00FFFFFF) ^ crc_tab[(crc ^ *block++) & 0xFF];
   }
   return (crc ^ 0xFFFFFFFF);
}

void crc32_gentab () {
   unsigned long crc, poly;
   int i, j;

   poly = 0xEDB88320L;
   for (i = 0; i < 256; i++)
   {
      crc = i;
      for (j = 8; j > 0; j--)
      {
	 if (crc & 1)
	 {
	    crc = (crc >> 1) ^ poly;
	 }
	 else
	 {
	    crc >>= 1;
	 }
      }
      crc_tab[i] = crc;
   }
}


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

typedef enum {
  STATUS = 0,
  MOVE_RIGHT = 1,
  MOVE_LEFT = 2
} MOTOR_COMMAND;

void tellMotorBoard(unsigned int cmd, unsigned int magnitude) {
  unsigned int data[2];
  data[0] = 0x0200000 | (isC1Board() << 25) | (isC0Board() << 24) | (cmd << 16);
  data[1] = magnitude;

  waiting_for_response = 1;
  
  sendDataMessage(data, 2);
}

void tellController(int ok) {
  unsigned int data[2];
  data[0] = 0x04100000 | (ok << 22);
  data[1] = ok;

  sendDataMessage(data, 2);
}

int checkAck(unsigned int data) {
  return (data >> 22) & 0x1; 
}

int doMotorCommand(int csr, int val) {
  int cmd;
  
  cmd = (csr >> 16) & 0xF;

  if (cmd == STATUS) {
    tellController(1);
  } else if (cmd == MOVE_RIGHT) {
    //Handle moving right here
    int currPosition = Stepper_GetPositionRequested(1);
    Stepper_SetPositionRequested(1, currPosition + val);

    tellController(1);
  } else if (cmd == MOVE_LEFT) {
    //Handle moving left here
    int currPosition = Stepper_GetPositionRequested(1);
    Stepper_SetPositionRequested(1, currPosition - val);

    tellController(1);
  } else {
    //Something is wrong
    tellController(0);
  }

  return 0;
}
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

int C0Board = 0;
int C1Board = 0;
int MotorBoard = 0;
int MonitorBoard = 0;

void setC0Board(int i) {
  C0Board = i;
}

void setC1Board(int i) {
  C1Board = i;
}

void setMotorBoard(int i) {
  MotorBoard = i;
}

void setMonitorBoard(int i) {
  MonitorBoard = i;
}

int isMaster() {
  return (isC0Board() | isC1Board()) && isPrime();
}

int isC0Board() {
  return C0Board;
}

int isC1Board() {
  return C1Board;
}

int isMotorBoard() {
  return MotorBoard;
}

int isMonitorBoard() {
  return MonitorBoard;
}

/*
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
    Can_SendData(&frame);
  }
	       
}


////////////////////////////////////////////////
*/

 ////////////////////////////////////////////////////////
 /*
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

  return 0;
  }*/
/*
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
  
  return 0;
}

void DebugQueueTask( void* p ) {
  (void)p;
  char* string;
  int level = 0;
  int have_message = 0;
  
  if (debug_queue_initialized == 0) {
    return;
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
*/
