#include "can.h"

//#define DEBUG_LOCAL
#ifdef DEBUG_LOCAL
 #include <stdio.h>
 #include <string.h>
 #define CONTROLLER_VERSION 100
 #define IO_PA02 2
 #define IO_PA07 7
 #define IO_PA16 16 
 #define IO_PA19 19
 #define IO_PA20 20
 #define CONTROLLER_OK 0
 #define CONTROLLER_ERROR_TOO_MANY_STOPS -1

#else
 #include "io.h"
 #include "config.h"
 #include "appled.h"

 #include "FreeRTOS.h"
 #include "task.h"
 #include "semphr.h"
 #include "queue.h"
 #include "AT91SAM7X256.h"
#endif

#if ( CONTROLLER_VERSION == 50 )
 #define CAN_ENABLE IO_PA02
 #define CAN_RX     IO_PA19
 #define CAN_TX     IO_PA20
#endif
#if ( CONTROLLER_VERSION == 90 )
 #define CAN_ENABLE IO_PB16
 #define CAN_RX     IO_PA19
 #define CAN_TX     IO_PA20
#endif
#if ( CONTROLLER_VERSION == 95 || CONTROLLER_VERSION == 100 )
 #define CAN_ENABLE IO_PA07
 #define CAN_RX     IO_PA19
 #define CAN_TX     IO_PA20
#endif


///////////////////////////////////////////////////
#ifdef DEBUG_LOCAL
char* values = "011111111111001100000000001001000110100010101100111100010011010101111001101111011110001001000110101111111111111";
int debuggetcount = 0;
unsigned int Io_GetValue(unsigned int type) {
  unsigned int invalue = 1;
  char mychar[2];
  mychar[1] = '\0';
  
  if (type == CAN_RX) {
    if (debuggetcount < strlen(values)) {
      mychar[0] = values[debuggetcount];
      invalue = atoi(mychar);
    }
    printf("Receiving a %d\n", invalue);
    debuggetcount++;
  } else {
    printf("Unknown receive port\n");
  }

  return invalue;
}

unsigned int Io_SetValue(unsigned int type, unsigned int value) {
  if (type == CAN_TX) { 
    //  printf("Transmitting a %d\n", value);
    printf("%d", value);
  } else {
    printf("Unknown send port\n");
  }
  return 0;
}

void Led_SetState(int val) {
  //printf("Setting main LED to %d\n", val);
}
void AppLed_SetState(int led, int val) {
  //printf("Setting AppLED %d to %d\n", led, val);
}


typedef int FastTimerEntry;
void FastTimer_InitializeEntry(FastTimerEntry* timer, void* func, int i, int j, int k) {
  //printf("Setting main LED to %d\n", val);
}
void FastTimer_Set(FastTimerEntry* timer) {
}
void FastTimer_SetActive(int i) {
}
void FastTimer_Cancel(FastTimerEntry* timer) {
}
void Sleep(int i) {
  printf("Sleeping for %d ms\n", i);
}

int Io_Start(int i, int j) {}
int Io_Stop(int i) {}
int Io_SetDirection(int i, int j) {}
int Io_SetPullup(int i, int j) {}

#define true 1
#define false 0
#endif
///////////////////////////////////////////////////


#define CAN_PERIOD 62500 //16 Hz

void Can_SendIRQCallback( int id );
void Can_ReceiveIRQCallback( int id );

int CanUsers = 0;
FastTimerEntry canReceiveTimer; // our TimerEntry
FastTimerEntry canSendTimer; // our TimerEntry
typedef struct canStandardPacket {
  unsigned int identifier : 11;
} CANSTANDARDPACKET;

int Can_SetActive( int state ) {
  if ( state )
    return Can_Start( );
  else
    return Can_Stop( );
}
 
 /**
   Returns the active state of the CAN subsystem.
   @return State - 1/non-zero (on) or 0 (off).
 */
 int Can_GetActive (void) {
   return CanUsers > 0;
 }

int Can_Start(void) {
   // int status;
   if ( CanUsers++ == 0 )
   {
     Can_Init();
   }
   return CONTROLLER_OK;
 }
 
int Can_Stop (void) {
  if ( CanUsers <= 0 )
    return CONTROLLER_ERROR_TOO_MANY_STOPS;
  
  if ( --CanUsers == 0 )
    Can_Stop();
  
  return CONTROLLER_OK;
}

unsigned int* canSendData;
int canSendLength = 0;
int canSendBitLength = 0;
int canSendI = 0;
int canSendJ = 0;
int canSendDone = 1;


int Can_SendData (Frame frame) {
  int myCanSendDone = 0;
  int wordpointer = 0;
  int bitpointer = 0;
  int i;
  unsigned int data[64];
  unsigned short crc;
  unsigned char ack;

  for (i = 0; i < 64; i++) {
    data[i] = 0;
  }
  /*data[0] = DOMINANT | (frame.identifier1 << 1) | (frame.rtr << 12) | (DOMINANT << 13) | (RECESSIVE << 14) | (frame.dlc << 15);
  wordpointer = 0;
  bitpointer = 19;*/
  data[0] = DOMINANT << 31 | (frame.identifier1 << 20) | (frame.rtr << 19) | (DOMINANT << 18) | (RECESSIVE << 17) | (frame.dlc << 13);
  wordpointer = 0;
  bitpointer = 12;
  
  canSendBitLength = 19;
#ifdef DEBUG_LOCAL
  printf("Data[0] = 0x%08X\n", data[0]);
#endif
  for (i = 0; i < frame.dlc * 8; i++) {
    data[wordpointer] =  data[wordpointer] | ( ((frame.data[i/8] >> (7 - (i % 8))) & 0x1) << bitpointer);
#ifdef DEBUG_LOCAL
    printf("bitpointer = %d, i = %d, shiftright = %d, shiftleft = %d, raw_data = 0x%08X, data = 0x%08x, data2 = 0x%08X\n", bitpointer, i, 7-i%8, bitpointer, frame.data[i/8], ((frame.data[i/8] >> (7 - i%8)) & 0x1),  ( ((frame.data[i/8] >> (7-i % 8)) & 0x1) << bitpointer));
    printf("Data[%d] = 0x%08X\n", wordpointer, data[wordpointer]);
#endif
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    
    canSendBitLength++;
  }

  //CRC
  crc = 0x1234 | 0x1;
  for (i = 0; i < 16; i++) {
    data[wordpointer] =  data[wordpointer] | ( ((crc >> (15 - (i % 16))) & 0x1) << bitpointer);
 #ifdef DEBUG_LOCAL
    printf("bitpointer = %d, i = %d, shiftright = %d, shiftleft = %d, raw_data = 0x%08X, data = 0x%08x, data2 = 0x%08X\n", bitpointer, i, 15-i%16, bitpointer, crc, ((crc >> (15 - i%16)) & 0x1),  ( ((crc >> (15-i % 16)) & 0x1) << bitpointer));
    printf("Data[%d] = 0x%08X\n", wordpointer, data[wordpointer]);
 #endif
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    canSendBitLength++;
  }
  

  //Ack and EOF
  for (i = 0; i < 12; i++) {
    data[wordpointer] =  data[wordpointer] | (1 << bitpointer);
 #ifdef DEBUG_LOCAL
    printf("bitpointer = %d, i = %d, shiftright = %d, shiftleft = %d, raw_data = 0x%08X, data = 0x%08x, data2 = 0x%08X\n", bitpointer, i, 1-i%2, bitpointer, 1, 1, 1 << bitpointer);
    printf("Data[%d] = 0x%08X\n", wordpointer, data[wordpointer]);
 #endif
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    canSendBitLength++;
  }


  
  canSendData = data;
  canSendLength = wordpointer + 1;
  canSendI = 0;
  canSendJ = 0;
  
  canSendDone = 0;
  Led_SetState(0);
  
  FastTimer_InitializeEntry( &canSendTimer, Can_SendIRQCallback, 0, CAN_PERIOD, true );
  FastTimer_Set( &canSendTimer ); // start our timer
#ifdef DEBUG_LOCAL
  canSendDone = 1;
#endif
  while(!myCanSendDone) {
    Sleep(1);
    myCanSendDone = canSendDone;
  }

  return 0;
}

unsigned int canSendBitLengthSoFar = 0;

void Can_SendIRQCallback( int id ) {
  //printf("sendcallback\n");
  if (canSendI >= canSendLength) {
    //AppLed_SetState(1, 1);
  }
  

  Io_SetValue(CAN_TX, (canSendData[canSendI] >> (31-canSendJ)) & 0x1);
  //AppLed_SetState(2, (canSendData[canSendI] >> canSendJ) & 0x1);
  canSendBitLengthSoFar++;

  canSendJ++;
  if (canSendJ >= 32) {
    canSendI++;
    canSendJ = 0;
  }
  
  //if (canSendI >= canSendLength) {
  if (canSendBitLengthSoFar >= canSendBitLength) {
    FastTimer_Cancel(&canSendTimer);
    Io_SetValue(CAN_TX, RECESSIVE);
    canSendBitLengthSoFar = 0;
    Led_SetState(1);
    canSendDone = 1;
  }
 
}


//Look at incoming telemetry and decide what to do with it
int Can_ReceiveData (unsigned int* data) {
  
}


typedef enum {
  IDLE = 1, 
  ID_FIELD1 = 2, 
  RTR_SRR = 4, 
  IDE = 8, 
  R1 = 11,
  R0 = 9, 
  ID_FIELD2 = 5, 
  RTR_EXTD = 6, 
  DLC = 10, 
  DATA = 12, 
  CRC = 13, 
  ACKFLAG = 14, 
  ACKDELIM = 15, 
  EOFRAME = 7, 
  INTERFRAME = 3,
} STATE;

//Process incoming telemetry
unsigned int State = IDLE;
unsigned int BitCount = 0;
unsigned int DataCount = 0;
Frame CurrFrame;

void Can_ReceiveIRQCallback( int id ) {
  int val;
  int i;

#ifdef DEBUG_LOCAL
  printf("State = %d\n", State);
#endif

  val = Io_GetValue(CAN_RX);
  AppLed_SetState(3, State & 0x1);
  AppLed_SetState(2, State & 0x2);
  AppLed_SetState(1, State & 0x4);
  AppLed_SetState(0, State & 0x8);
  Led_SetState(val);

  
  if ( (State == IDLE) && (val == DOMINANT) ) {
    //Set the timer to run at the can bus rate
    //FastTimer_SetTime(&canReceiveTimer, CAN_PERIOD);

    CurrFrame.standard = 0;
    CurrFrame.identifier1 = 0;
    CurrFrame.identifier2 = 0;
    CurrFrame.rtr = 0;
    CurrFrame.dlc = 0;
    for (i = 0; i < 8; i++) {
      CurrFrame.data[i] = 0;
    }
    CurrFrame.crc = 0;
    CurrFrame.ack = 0;
    CurrFrame.eof = 0;
    State = ID_FIELD1;
  }
  
  else if ( (State == ID_FIELD1) ) {
    CurrFrame.identifier1 = CurrFrame.identifier1 | (val << (10 - BitCount));
    BitCount++;
    
    if (BitCount >= 11) {
      BitCount = 0;
      State = RTR_SRR;
    }    
  }

  else if (State == RTR_SRR) {
    CurrFrame.rtr = val;
    State = IDE;
  }

  else if (State == IDE) {
    CurrFrame.standard = (val == DOMINANT);
    if (CurrFrame.standard) {
      State = R0;
    } else {
      State = ID_FIELD2;
    }
  }

  else if (State == R0) {
    State = DLC;
  }


  else if (State == ID_FIELD2) {
    CurrFrame.identifier2 = CurrFrame.identifier2 | (val << (17 - BitCount));
    BitCount++;
    
    if (BitCount >= 18) {
      BitCount = 0;
      State = RTR_EXTD;
    }    
  }

  else if (State == RTR_EXTD) {
    CurrFrame.rtr = val;
    State = R1;
  }

  else if (State == R1) {
    State = R0;
  }
  
  else if (State == DLC) {
    CurrFrame.dlc = CurrFrame.dlc | (val << (3 - BitCount));
    BitCount++;
    
    if (BitCount >= 4) {
      BitCount = 0;
      if (CurrFrame.dlc == 0) {
	State = CRC;
      } else {
	State = DATA;
      }
    }    
  }

  else if (State == DATA) {
    CurrFrame.data[DataCount] = CurrFrame.data[DataCount] | (val << (7 - BitCount));
    BitCount++;

#ifdef DEBUG_LOCAL
    printf("bitcount = %d, datacount = %d\n", BitCount, DataCount);
#endif
    
    if (BitCount >= 8) {
      BitCount = 0;
      DataCount++;
    }
    if (DataCount >= CurrFrame.dlc) {
      BitCount = 0;
      DataCount = 0;
      State = CRC;
    }
  }

  else if (State == CRC) {
    CurrFrame.crc = CurrFrame.crc | (val << (15 - BitCount));
    BitCount++;
  
    if (BitCount >= 16) {
      BitCount = 0;
      State = ACKFLAG;
    }
  }

  else if (State == ACKFLAG) {
    CurrFrame.ack = val;
    State = ACKDELIM;
    //Do ack stuff here
  }

  else if (State == ACKDELIM) {
    CurrFrame.ack = CurrFrame.ack | (CurrFrame.ack << 1);
    State = EOFRAME;
  }
    
  else if (State == EOFRAME) {
    CurrFrame.eof = CurrFrame.eof | (val << (6 - BitCount));
    BitCount++;

    if (BitCount >= 7) {
      BitCount = 0;
      State = INTERFRAME;
    }
  }

  else if (State == INTERFRAME) {
    BitCount++;
    if (BitCount >= 3) {
      //Set the timer to run as fast as possible
      //FastTimer_SetTime(&canReceiveTimer, 1);

      BitCount = 0;
      State = IDLE;
    }
  }

  
}



int Can_Init(void) {
  // Try to lock the enable pin
  int status = Io_Start( CAN_ENABLE, true );
  if ( status != CONTROLLER_OK )
    return status;
  
  // Try to lock the tx pin
  status = Io_Start( CAN_TX, true );
  if ( status != CONTROLLER_OK ) {
    Io_Stop( CAN_ENABLE );
    return status;
  }
 
   // Try to lock the rx pin
  status = Io_Start( CAN_RX, true );
  if ( status != CONTROLLER_OK ) {
    Io_Stop( CAN_ENABLE );
    Io_Stop( CAN_TX );
    return status;
  }
 
  Io_SetDirection( CAN_TX, true );
  Io_SetDirection( CAN_RX, false );
  Io_SetPullup( CAN_RX, false );
  
  Io_SetDirection( CAN_ENABLE, true );
  Io_SetValue( CAN_ENABLE, false );

  Io_SetValue( CAN_TX, RECESSIVE);
  
  //Startup interrupt driven receive that triggers on the interval defied by CAN_PERIOD
  FastTimer_SetActive(true);
  FastTimer_InitializeEntry( &canReceiveTimer, Can_ReceiveIRQCallback, 0, CAN_PERIOD, true );
  //FastTimer_InitializeEntry( &canReceiveTimer, Can_ReceiveIRQCallback, 0, 1, true );
  FastTimer_Set( &canReceiveTimer ); // start our timer
 
  return CONTROLLER_OK;
}

#ifdef DEBUG_LOCAL
int main() {
  Frame frame;
  int i;
  
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
  
  Can_SendData(frame);
  canSendDone = 0;
  printf("canSendLength = %d, canSendI = %d, canSendJ = %d\n", canSendLength, canSendI, canSendJ);
  while(!canSendDone) {
    Can_SendIRQCallback(0);
  }
  printf("\n");
  
  /*
  for(i = 0; i < 150; i++) {
    Can_ReceiveIRQCallback(0);
  }
  printf("Standard = %x, ID = %x, RTR = %x, Data[0] = %x, Data[1] = %x, Data[2] = %x, Data[3] = %x, Data[4] = %x, Data[5] = %x, Data[6] = %x, Data[7] = %x, CRC = %x, Ack = %x, EOF = %x\n", CurrFrame.standard, CurrFrame.identifier1, CurrFrame.rtr, CurrFrame.data[0], CurrFrame.data[1], CurrFrame.data[2], CurrFrame.data[3], CurrFrame.data[4], CurrFrame.data[5], CurrFrame.data[6], CurrFrame.data[7], CurrFrame.crc, CurrFrame.ack, CurrFrame.eof);
  */
  return 0;
}
#endif
