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
void sendStatus(unsigned int value);
void sendNAck(unsigned int value);
void tellController(int ok, int val);
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

int motorZeroPoint = 0;

void Run( ) // this task gets called as soon as we boot up.
{
  // Do this right quick after booting up - otherwise we won't be recognised
  Usb_SetActive( 0 );
  //  AppLed_SetState(0, 1);
  
  // Setup up which board this is
  setC0Board((DipSwitch_GetValue() & 3) == 0);
  setC1Board((DipSwitch_GetValue() & 3) == 1);
  setMotorBoard((DipSwitch_GetValue() & 3) == 2);
  setMonitorBoard((DipSwitch_GetValue() & 3) == 3);
	
  AppLed_SetState(0, 0);
  AppLed_SetState(1, 0);
  AppLed_SetState(2, 0);
  AppLed_SetState(3, 0);
  
  if (!isMonitorBoard()) {
    TaskCreate( stroke_wdt, "stroke", 400, 0, 1);
    gen_alive(0);
    TaskCreate( error_injector, "errinj", 400, 0, 1);
  }
  

  //  AppLed_SetState(0, isC0Board());
  //  AppLed_SetState(1, isC1Board());
  //  AppLed_SetState(2, isMotorBoard());
  //  AppLed_SetState(3, isMonitorBoard());
	 
  /*
    if (isMonitorBoard()) {
    int i;
    DigitalOut_SetValue(0, 0);
    DigitalOut_SetValue(1, 0);

    //for (i = 0; i < 96; i++) {
    //  DigitalOut_SetValue(0, !DigitalOut_GetValue(0));
    //  DigitalOut_SetValue(1, !DigitalOut_GetValue(1));
    //}
    }*/

  // Starts the network up.  Will not return until a network is found...
  Network_SetDhcpEnabled(1);
  Network_SetActive( true );
  //  AppLed_SetState(1, 1);

  // calibrate the shuttle keep moving forward until it trips index sensor
  if (isMotorBoard()) {
    Stepper_SetActive(1, 1);
    int currentPos = 10;
    while (AnalogIn_GetValue(2) > 0x0100) {
      Stepper_SetPositionRequested(1, currentPos);
      while (Stepper_GetPosition(1) != currentPos) Sleep(10);
      currentPos += 2;
    }
    motorZeroPoint = currentPos;
  }


  //UDP Server/Client
  while( udpsendsocket == NULL ) {
    //    AppLed_SetState(2, !AppLed_GetState(2));
    udpsendsocket = DatagramSocket( 0 );
    Sleep( 100 );
  }
  while( udplistensocket == NULL ) {
    //    AppLed_SetState(3, !AppLed_GetState(3));
    udplistensocket = DatagramSocket( 10228 );
    Sleep( 100 );
  }
  
  TaskCreate(receiveMotorCommandTask, "motorreceive", 400, 0, 1);
  if (!isMotorBoard() && !isMonitorBoard()) {
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
  char* localMessagewithcrc;
  int i;

  localMessageInt = Malloc(sizeof(unsigned int) * (length + 1));
  localMessage = Malloc(sizeof(unsigned char) * ((length * 4)));
  localMessagewithcrc = Malloc(sizeof(unsigned char) * ((length * 4) + 4));
  
  for (i = 0; i < length; i++) {
    localMessageInt[i] = message[i];
  }

  int2char(localMessage, localMessageInt, length);

  // error injector indicates corrupted crc
  if (getFduMode() == 1) {
	  localMessageInt[length] = crc32(localMessage, length*4) + 1;
  } else {
	  localMessageInt[length] = crc32(localMessage, length*4);
  }
	
  int2char(localMessagewithcrc, localMessageInt, length+1);
  
  if (isPrime() || isMotorBoard()) {
    sentLength = DatagramSocketSend( udpsendsocket, IP_ADDRESS( 255,255,255,255), 10228, localMessagewithcrc, ((length+1)*4));    
  } else {
    Sleep(1);
  }
  
  Free(localMessageInt);
  Free(localMessage);
  Free(localMessagewithcrc);

  return (sentLength > 0);
}

int waiting_for_response = 0;
int current_direction = 0;
int error_count = 0;
int error_noresponse_count = 0;

typedef enum {
  STATUS = 0,
  MOVE_FORWARD = 1,
  MOVE_BACKWARD = 2
} MOTOR_COMMAND;

const int WAIT_TIME = 30;
const int STEP_SIZE = 4;
const int MIN_POSITION = 0x39;
const int MAX_POSITION = 0x6B;

void sendMotorCommandTask(void* p) {
  (void)p;
  
  while(true) {
    int analogIn = AnalogIn_GetValue(1);
    
    if (analogIn > 0x20) {
      current_direction = MOVE_BACKWARD;
    } else {
      current_direction = MOVE_FORWARD;
    }
    
    //if (analogIn > MAX_POSITION) 
    //  current_direction = MOVE_BACKWARD;
    //else if (analogIn < MIN_POSITION)
    //  current_direction = MOVE_FORWARD;
    
    //// for debug	  
    //	dataToSend[0] = 0x0100000 | (isC1Board() << 25) | (isC0Board() << 24);
    //	dataToSend[1] = AnalogIn_GetValue(1);
    //	sendDataMessage(dataToSend, 2);
    
    //sendStatus(analogIn);
    if (waiting_for_response) {
      // Didn't get a response the last time we sent a command
      sendNAck(0xFFFFFFFF);
      waiting_for_response = 0;
      error_noresponse_count++;
      if (error_noresponse_count > 10) TaskDelete(stroke_wdt);
    } else {
      error_noresponse_count = 0;
    }
    
    tellMotorBoard(current_direction, STEP_SIZE);
 
   
    Sleep(WAIT_TIME);
  }
}


unsigned char* echoData;
void receiveMotorCommandTask(void* p) {
  (void)p;
  int address, port, size, i;
  unsigned char* packet = Malloc(sizeof(char) * 1000);
  //Debug(DEBUG_ALWAYS, "IP Address = 0x%08x", address);
  
  //DigitalOut_SetValue(4, 0);
  //DigitalOut_SetValue(5, 0);
  
  //if (isMonitorBoard()) {
  //  echoData = Malloc(sizeof(unsigned char) * 256);
  //}

  for (i = 0; i < 20; i++) {
    DatagramSocketReceive(udplistensocket, 10228, &address, &port, packet, 1000);
    waiting_for_response = 0;
  }
  while(true) {
    unsigned int recv_crc32, calc_crc32;
    size = DatagramSocketReceive(udplistensocket, 10228, &address, &port, packet, 1000);
    if (size != 0) {
      unsigned int* incoming;
      unsigned int incomingSize = ceil(size / 4.0);
      incoming = Malloc(sizeof(unsigned int) * incomingSize);
      char2int(incoming, packet, size);
      //      AppLed_SetState(3, !AppLed_GetState(3));
      
      
      recv_crc32 = incoming[incomingSize - 1];
      calc_crc32 = crc32(packet, size - 4);
      
      if (isMonitorBoard()) {
        AppLed_SetState(0, !AppLed_GetState(0));
        receiveMotorCommandEcho(packet, size);
      } else if (isMotorBoard()) {
        if (recv_crc32 == calc_crc32) {
          if (((incoming[0] & 0x03000000) != 0) && ((incoming[0] & 0x00200000) != 0)) {
            //            AppLed_SetState(0, !AppLed_GetState(0));
            doMotorCommand(incoming[0], incoming[1]);
            //tellController(1, 0);
          } else if (((incoming[0] & 0x03000000) != 0) && ((incoming[0] & 0x00100000) != 0)) {
            //Ignore status messages
          } else {
            tellController(0, -1);
          }
        } else {
          tellController(0, -1);
        }
      } else if (isMaster()) {
        if (waiting_for_response) {
          if (!checkAck(incoming[0])) {
            //Something bad happened. Deal with it
            if (incoming[1] == 0xFFFFFFFF) error_count++;
            if (error_count >= 10) TaskDelete(stroke_wdt);
          } else {
			error_count = 0;
          }
        } else {
          //Did not expect someone to talk. Deal with it.
        }
        waiting_for_response = 0;
      }
	
      
      Free(incoming);
    }
    Free(packet);
    //DatagramSocketClose(socket);
    //Osc_CreateMessage( OSC_CHANNEL_UDP, "/motorboard/movemoterup", ",s",  "blah");
    //Osc_SendPacket( OSC_CHANNEL_UDP );
  }
}

FastTimerEntry echoTimer; // our TimerEntry
int echoLengthInBytes = 0;
int echoBitPointer = 0;
int echoBytePointer = 0;
int echoRunning = 0;
void receiveMotorCommandEchoIRQCallback(int id);
void receiveMotorCommandEchoIRQCallback(int id) {
  (void)id;

  if (echoBytePointer < echoLengthInBytes) {
    DigitalOut_SetValue(1, (echoData[echoBytePointer] >> (7-echoBitPointer)) & 0x1);
    DigitalOut_SetValue(0, !DigitalOut_GetValue(0));  
    
    if (echoBitPointer == 7) {
      echoBitPointer = 0;
      echoBytePointer++;
    } else {
      echoBitPointer++;
    }
  } else {
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
 
  Sleep(1);
 
  while(echoRunning) {
    Sleep(1);
  }

  Free(echoData);
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

void tellMotorBoard(unsigned int cmd, unsigned int magnitude) {
  unsigned int data[2];
  data[0] = 0x00200000 | (isC1Board() << 25) | (isC0Board() << 24) | (cmd << 16);
  data[1] = magnitude;

  if (isMaster()) {
    waiting_for_response = 1;
  }
  sendDataMessage(data, 2);
}

void sendStatus(unsigned int value) {
  unsigned int data[2];
  data[0] = 0x00100000 | (isMotorBoard() << 26) | (isC1Board() << 25) | (isC0Board() << 24);
  data[1] = value;

  waiting_for_response = 0;
  
  sendDataMessage(data, 2);
}

void sendNAck(unsigned int value) {
  unsigned int data[2];
  data[0] = 0x00500000 | (isMotorBoard() << 26) | (isC1Board() << 25) | (isC0Board() << 24);
  data[1] = value;

  waiting_for_response = 0;
  
  sendDataMessage(data, 2);
}

void tellController(int ok, int val) {
  unsigned int data[2];
  data[0] = 0x04100000 | (ok << 22);
  data[1] = val;

  sendDataMessage(data, 2);
}

int checkAck(unsigned int data) {
  return (data >> 22) & 0x1; 
}

int doMotorCommand(int csr, int val) {
  int cmd;
  
  
  if (Stepper_GetPosition(1) != Stepper_GetPositionRequested(1)) {
    tellController(0, Stepper_GetPosition(1));
    //Stepper_SetActive(1, 0);
    //Stepper_SetActive(1, 1);
    
    return -1;
  }
  

  cmd = (csr >> 16) & 0xF;

  if (cmd == STATUS) {
    tellController(1, Stepper_GetPosition(1));
  } else if (cmd == MOVE_FORWARD) {
    //Handle moving forward here
    int currPosition = Stepper_GetPositionRequested(1);
    if (AnalogIn_GetValue(2) > 0x0100) {
      Stepper_SetPositionRequested(1, currPosition + val);
      tellController(1, Stepper_GetPosition(1));
    } else {
      tellController(0, Stepper_GetPosition(1));
    }
  } else if (cmd == MOVE_BACKWARD) {
    //Handle moving backward here
    int currPosition = Stepper_GetPositionRequested(1);
    if ( (motorZeroPoint - 980) < (currPosition - val) ) {
      Stepper_SetPositionRequested(1, currPosition - val);
      tellController(1, Stepper_GetPosition(1));
    } else {
      tellController(0, Stepper_GetPosition(1));
    }
  } else {
    //Something is wrong
    tellController(0, Stepper_GetPosition(1));
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
