#include "can.h"
#include <math.h>

#ifndef SAM7_GCC
  #define DEBUG_LOCAL
#endif

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

 #define DEBUG_ALWAYS 0
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
//char* values = "011111111111001100000000001001000110100010101100111100010011010101111001101111011110001001000110101111111111111";
  char* values = "0111111111110011000000000010010001101000101011001111000100110101011110011011110111111110000100110011111111111111";
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
    //printf("Receiving a %d\n", invalue);
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

void TaskCreate(void* funcame, char* title, int a, int b, int c) {
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
void FastTimer_SetTime(FastTimerEntry* timer, unsigned int rate) {
}
void FastTimer_SetActive(int i) {
}
void FastTimer_Cancel(FastTimerEntry* timer) {
}
void Sleep(int i) {
  printf("Sleeping for %d ms\n", i);
}
void* Malloc(int i) {
  return malloc(i);
}
void Free(void* i) {
  free(i);
}
	

#define Debug(target, ...) printf (__VA_ARGS__)



int Io_Start(int i, int j) {}
int Io_Stop(int i) {}
int Io_SetDirection(int i, int j) {}
int Io_SetPullup(int i, int j) {}

#define true 1
#define false 0
#endif
///////////////////////////////////////////////////


//#define CAN_PERIOD 62500 //16 Hz
//#define CAN_PERIOD 10 //100 kHz
#define CAN_PERIOD 1000 //1 kHz


void Can_SendIRQCallback( int id );
void Can_ReceiveIRQCallback( int id );
unsigned int Debug2( int level, char* format, ... );

///////////

unsigned long crc15(unsigned char* p, unsigned long len) {
  int order = 15;
  unsigned long polynom = 0x4599;
  unsigned int crcmask = ((((unsigned long)1<<(order-1))-1)<<1)|1;
  unsigned int crchighbit = (unsigned long)1<<(order-1);
  // bit by bit algorithm with augmented zero bytes.
  // does not use lookup table, suited for polynom orders between 1...32.

  unsigned long i, j, c, bit;
  unsigned long crc = 0;

  for (i=0; i<len; i++) {

    c = (unsigned long)*p++;
    
    for (j=0x80; j; j>>=1) {

      bit = crc & crchighbit;
      crc<<= 1;
      if (c & j) crc|= 1;
      if (bit) crc^= polynom;
    }
  }	

  for (i=0; i<order; i++) {
    bit = crc & crchighbit;
    crc<<= 1;
    if (bit) crc^= polynom;
  }

  crc&= crcmask;
  return(crc);
}



///////////


int CanUsers = 0;
FastTimerEntry canReceiveTimer; // our TimerEntry
int fastSampleRate; // our TimerEntry
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
int canSendBitLength = 0;
int canSendI = 0;
int canSendJ = 0;
int canSendDone = 1;
unsigned int canSendBitLengthSoFar = 0;

int Can_SendData (Frame* frame) {
  int myCanSendDone = 0;
  int wordpointer = 0;
  int bitpointer = 0;
  int i;
  unsigned int* data;
  unsigned short crc;
  unsigned char ack;
  unsigned char data_for_crc[16];
  unsigned int data_for_crc_bytes;
  
  
  
  data = MallocWait(sizeof(unsigned int) * 20, 10);
  for (i = 0; i < 5; i++) {
    data[i] = 0;
  }
  data[0] = DOMINANT << 31 | (frame->identifier1 << 20) | (frame->rtr << 19) | (DOMINANT << 18) | (RECESSIVE << 17) | (frame->dlc << 13);
  wordpointer = 0;
  bitpointer = 12;
  
  canSendBitLength = 19;
  //Debug(DEBUG_ALWAYS, "Data Sending[0] = 0x%08X\n", data[0]);
  for (i = 0; i < frame->dlc * 8; i++) {
    data[wordpointer] =  data[wordpointer] | ( ((frame->data[i/8] >> (7 - (i % 8))) & 0x1) << bitpointer);
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    
    canSendBitLength++;
  }

  //CRC
  data_for_crc_bytes =  ceil(canSendBitLength / 8.0);
  //Debug(DEBUG_ALWAYS, "Size of Data for CRC Sending = %d\n", data_for_crc_bytes);
  for (i = 0; i < data_for_crc_bytes; i++) {
    if (i % 4 == 0) {
      data_for_crc[i] = (data[i/4] >> 24) & 0xFF;
    } else if (i % 4 == 1) {
      data_for_crc[i] = (data[i/4] >> 16) & 0xFF;
    } else if (i % 4 == 2) {
      data_for_crc[i] = (data[i/4] >> 8) & 0xFF;
    } else {
      data_for_crc[i] = (data[i/4] >> 0) & 0xFF;
    }
  }
  /*{
    char* string = (char*) Malloc(sizeof(char) * data_for_crc_bytes * 40);
    string[0] = 0;
    for(i = 0; i < data_for_crc_bytes; i++) {
      if (i == 0) {
	sprintf(string, "(CRC Sending) %d:0x%02x", i, data_for_crc[i]);
      } else {
	sprintf(string, "%s %d:0x%02X", string, i, data_for_crc[i]);
      }
    }
    //Debug(DEBUG_ALWAYS, "%s\n", string);
    Free(string);
    }*/
  
  crc = crc15(data_for_crc, data_for_crc_bytes);
  
  crc = (crc << 1) | 0x1;
  for (i = 0; i < 16; i++) {
    data[wordpointer] =  data[wordpointer] | ( ((crc >> (15 - (i % 16))) & 0x1) << bitpointer);
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    canSendBitLength++;
  }
  

  //Ack and EOF
  for (i = 0; i < 12; i++) {
    data[wordpointer] =  data[wordpointer] | (RECESSIVE << bitpointer);
    bitpointer--;
    if (bitpointer == -1) {
      bitpointer = 31;
      wordpointer++;
    }
    canSendBitLength++;
  }


  //Debug2(DEBUG_ALWAYS, "\nPacket Sending:\n ID = 0x%03X\n Remote = %d\n ByteCount = %d\n Data[0] = 0x%02X\n Data[1] = 0x%02X\n Data[2] = 0x%02X\n Data[3] = 0x%02X\n Data[4] = 0x%02X\n Data[5] = 0x%02X\n Data[6] = 0x%02X\n Data[7] = 0x%02X\n CRC = 0x%04X\n", frame->identifier1, frame->rtr, frame->dlc, frame->data[0], frame->data[1], frame->data[2], frame->data[3], frame->data[4], frame->data[5], frame->data[6], frame->data[7], crc);
  
  
  canSendData = data;
  canSendI = 0;
  canSendJ = 0;
  canSendBitLengthSoFar = 0;

  canSendDone = 0;
  //Led_SetState(0);
  
  //Debug2(DEBUG_ALWAYS, "Beginning frame transmission");
  FastTimer_InitializeEntry( &canSendTimer, Can_SendIRQCallback, 0, CAN_PERIOD, true );
  FastTimer_Set( &canSendTimer ); // start our timer
#ifdef DEBUG_LOCAL
  canSendDone = 1;
#endif
  while(!myCanSendDone) {
    Sleep(1);
    //Debug(DEBUG_ALWAYS, "CanSendDone = %d", myCanSendDone);
    myCanSendDone = canSendDone;
  }

  return 0;
}

  

void Can_SendIRQCallback( int id ) {
  if (canSendBitLengthSoFar < canSendBitLength && !canSendDone) {
    if (isPrime()) {
      Io_SetValue(CAN_TX, (canSendData[canSendI] >> (31-canSendJ)) & 0x1);
    } else {
      Io_SetValue(CAN_TX, RECESSIVE);
    }
    AppLed_SetState(2, (canSendData[canSendI] >> canSendJ) & 0x1);
    canSendBitLengthSoFar++;
    

    canSendJ++;
    if (canSendJ >= 32) {
      canSendI++;
      canSendJ = 0;
    }
  }
  if (canSendBitLengthSoFar >= canSendBitLength) {
    unsigned int* mydata = canSendData;
    FastTimer_Cancel(&canSendTimer);
    Io_SetValue(CAN_TX, RECESSIVE);
    //Led_SetState(1);
    canSendDone = 1;
    canSendData = 0;
    
    Free(mydata);
    //canSendBitLength = 0;
    //canSendBitLengthSoFar = 0;
    
    //canSendData = (unsigned int*) 0;
    //canSendI = 0;
    //canSendJ = 0;

  }
 
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
  ERROR_FLAG = 16,
  ERROR_DELIM = 17,
  UNKNOWN = 31
} STATE;

//Process incoming telemetry
unsigned int State = IDLE;
unsigned int ObservingFrame = 0;
unsigned int ReceivingFrame = 0;
unsigned int BitCount = 0;
unsigned int DataCount = 0;
Frame CurrFrame;
char tempstring[60];
    
int Can_CheckCRC () {
  Frame lframe;
  int i;
  int count;
  unsigned int crc;
  unsigned char data[12];
  
  //Copy the frame to local memory
  lframe.standard = CurrFrame.standard;
  lframe.identifier1 = CurrFrame.identifier1;
  lframe.identifier2 = CurrFrame.identifier2;
  lframe.rtr = CurrFrame.rtr;
  lframe.dlc = CurrFrame.dlc;
  for (i = 0; i < 8; i++) {
    lframe.data[i] = CurrFrame.data[i];
  }
  lframe.crc = CurrFrame.crc;
  lframe.ack = CurrFrame.ack;
  lframe.eof = CurrFrame.eof;
  
  //Check it for CRC error
  for (i = 0; i < 12; i++) {
    data[i] = 0;
  }
  data[0] = (DOMINANT << 7) | (lframe.identifier1 >> 4);
  data[1] = (lframe.identifier1 << 4) | (lframe.rtr << 3) | (DOMINANT << 2) | (RECESSIVE << 1) | (lframe.dlc >> 3);
  data[2] = (lframe.dlc << 5);

  count = 2;
  for (i = 0; i < lframe.dlc; i++) {
    data[i+2] = data[i+2] | (lframe.data[i] >> 3);
    data[i+3] = lframe.data[i] << 5;
    count++;
  }
  count++;

  /*
  for(i = 0; i < count; i++) {
    char* string = (char*) Malloc(sizeof(char) * count * 21);
    string[0] = 0;
    for(i = 0; i < count; i++) {
      if (i == 0) {
	sprintf(string, "(CRC Receiving) 0:0x%02x", data[0]);
      } else {
	sprintf(string, "%s %d:0x%02X", string, i, data[i]);
      }
    }
    Debug(DEBUG_ALWAYS, "%s\n", string);
    Free(string);
    }
  */
  crc = (crc15(data, count) << 1) | RECESSIVE;
  CurrFrame.crc = crc;
  {
    Debug2(DEBUG_ALWAYS, "Packet Received");
    sprintf(tempstring, "-- ID = %d, Remote = %d, Bytecount = %d", lframe.identifier1, lframe.rtr, lframe.dlc);
    Debug2(DEBUG_ALWAYS, tempstring);
    sprintf(tempstring, "-- Data = 0x%02X%02X%02X%02X%02X%02X%02X%02X", lframe.data[0], lframe.data[1], lframe.data[2], lframe.data[3], lframe.data[4], lframe.data[5], lframe.data[6], lframe.data[7]);
    Debug2(DEBUG_ALWAYS, tempstring);
    //char tempstring[215];
    //sprintf(tempstring, "\nPacket for Received CRC Calc:\n ID = 0x%03X\n Remote = %d\n ByteCount = %d\n Data[0] = 0x%02X\n Data[1] = 0x%02X\n Data[2] = 0x%02X\n Data[3] = 0x%02X\n Data[4] = 0x%02X\n Data[5] = 0x%02X\n Data[6] = 0x%02X\n Data[7] = 0x%02X\n CRC = 0x%04X\n", lframe.identifier1, lframe.rtr, lframe.dlc, lframe.data[0], lframe.data[1], lframe.data[2], lframe.data[3], lframe.data[4], lframe.data[5], lframe.data[6], lframe.data[7], crc);
    //Debug2(DEBUG_ALWAYS, tempstring);
    //Debug2(DEBUG_ALWAYS, "\nPacket for Received CRC Calc:\n ID = 0x%03X\n Remote = %d\n ByteCount = %d\n Data[0] = 0x%02X\n Data[1] = 0x%02X\n Data[2] = 0x%02X\n Data[3] = 0x%02X\n Data[4] = 0x%02X\n Data[5] = 0x%02X\n Data[6] = 0x%02X\n Data[7] = 0x%02X\n CRC = 0x%04X\n", lframe.identifier1, lframe.rtr, lframe.dlc, lframe.data[0], lframe.data[1], lframe.data[2], lframe.data[3], lframe.data[4], lframe.data[5], lframe.data[6], lframe.data[7], crc);
  }
  if (crc != lframe.crc) {
    sprintf(tempstring, "-- CRC calculated (0x%04X) does not equal CRC sent (0x%04X)", crc, lframe.crc);
    Debug2(DEBUG_ALWAYS, tempstring);
    //Debug2(DEBUG_ALWAYS, "CRC calculated (0x%04X) does not equal CRC sent (0x%04X)", crc, lframe.crc);
    return 1;
  } else {
    sprintf(tempstring, "-- CRC calculated (0x%04X) does equal CRC sent (0x%04X)", crc, lframe.crc);
    Debug2(DEBUG_ALWAYS, tempstring);
    //Debug2(DEBUG_ALWAYS, "CRC calculated (0x%04X) does equal CRC sent (0x%04X)", crc, lframe.crc);
    return 0;
  }
  
}

//Look at incoming telemetry and decide what to do with it
int Can_PostProcessData (void* p) {
  
  (void)p;
  Frame* lframe;
  int i;
  int count;
  unsigned int crc;
  unsigned char data[12];

  lframe = (Frame*) MallocWait(sizeof(Frame), 10);
  
  //Copy the frame to local memory
  lframe->standard = CurrFrame.standard;
  lframe->identifier1 = CurrFrame.identifier1;
  lframe->identifier2 = CurrFrame.identifier2;
  lframe->rtr = CurrFrame.rtr;
  lframe->dlc = CurrFrame.dlc;
  for (i = 0; i < 8; i++) {
    lframe->data[i] = CurrFrame.data[i];
  }
  lframe->crc = CurrFrame.crc;
  lframe->ack = CurrFrame.ack;
  lframe->eof = CurrFrame.eof;
  

  //Debug2(DEBUG_ALWAYS, "\nPacket Receiving:\n ID = 0x%03X\n Remote = %d\n ByteCount = %d\n Data[0] = 0x%02X\n Data[1] = 0x%02X\n Data[2] = 0x%02X\n Data[3] = 0x%02X\n Data[4] = 0x%02X\n Data[5] = 0x%02X\n Data[6] = 0x%02X\n Data[7] = 0x%02X\n CRC = 0x%04X\n Ack = %x\n EOF = 0x%02X", lframe->identifier1, lframe->rtr, lframe->dlc, lframe->data[0], lframe->data[1], lframe->data[2], lframe->data[3], lframe->data[4], lframe->data[5], lframe->data[6], lframe->data[7], lframe->crc, lframe->ack, lframe->eof);
  //Debug(DEBUG_ALWAYS, "Packet Receiving:");
  /*  Debug(DEBUG_ALWAYS, "ID = 0x%03X", lframe->identifier1);
  Debug(DEBUG_ALWAYS, "Remote = %d", lframe->rtr);
  Debug(DEBUG_ALWAYS, "ByteCount = %d", lframe->dlc);
  Debug(DEBUG_ALWAYS, "Data[0] = 0x%02X", lframe->data[0]);
  Debug(DEBUG_ALWAYS, "Data[1] = 0x%02X", lframe->data[1]);
  Debug(DEBUG_ALWAYS, "Data[2] = 0x%02X", lframe->data[2]);
  Debug(DEBUG_ALWAYS, "Data[3] = 0x%02X", lframe->data[3]);
  Debug(DEBUG_ALWAYS, "Data[4] = 0x%02X", lframe->data[4]);
  Debug(DEBUG_ALWAYS, "Data[5] = 0x%02X", lframe->data[5]);
  Debug(DEBUG_ALWAYS, "Data[6] = 0x%02X", lframe->data[6]);
  Debug(DEBUG_ALWAYS, "Data[7] = 0x%02X", lframe->data[7]);
  Debug(DEBUG_ALWAYS, "CRC = 0x%04X", lframe->crc);
  Debug(DEBUG_ALWAYS, "Ack = %x", lframe->ack);
  Debug(DEBUG_ALWAYS, "EOF = 0x%02X", lframe->eof);
*/
  //Debug(DEBUG_ALWAYS, "");
  //Put in routines to do specific action based on above fields. Recommened using case statement
  /* case (lframe.identifier1) {
     
     }
  */
  
  Free(lframe);
  return 0;
}



void Can_ReceiveIRQCallback( int id ) {
  int val;
  int i;

  //Debug(DEBUG_ALWAYS, "State = %d\n", State);

  val = Io_GetValue(CAN_RX);

  if (State == IDLE && val == DOMINANT) {
    //Set the timer to run at the can bus rate
    //FastTimer_SetTime(&canReceiveTimer, CAN_PERIOD);
    
  }

  AppLed_SetState(3, State & 0x1);
  AppLed_SetState(2, State & 0x2);
  AppLed_SetState(1, State & 0x4);
  AppLed_SetState(0, State & 0x8);
  //Led_SetState(val);

  
  if ( (State == IDLE) && (val == DOMINANT) ) {
   
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
    Io_SetValue(CAN_TX, DOMINANT);
  }

  else if (State == ACKDELIM) {
    CurrFrame.ack = CurrFrame.ack | (CurrFrame.ack << 1);
    State = EOFRAME;
    Io_SetValue(CAN_TX, RECESSIVE);
  }
    
  else if (State == EOFRAME) {
    if ((BitCount == 0) && Can_CheckCRC()) {
      //We have a CRC error, transmit an ERROR frame
      //Can_SendErrorFrame();
      Io_SetValue(CAN_TX, DOMINANT);
      //Debug(DEBUG_ALWAYS, "Sending error\n");
      BitCount = 1;
      State = ERROR_FLAG;
      return;
    }
    
    if (val == DOMINANT) {
      BitCount = 1;
      State = ERROR_FLAG;
    }
    CurrFrame.eof = CurrFrame.eof | (val << (6 - BitCount));
    BitCount++;

    if (BitCount >= 7) {
      BitCount = 0;
      State = INTERFRAME;
      //TaskCreate(Can_PostProcessData, "canpost", 400, 0, 1);
      Can_PostProcessData((void*) 0);
    }
  }
  
  else if (State == ERROR_FLAG) {
    BitCount++;
    
    if (val != DOMINANT) {
      Io_SetValue(CAN_TX, DOMINANT);
    }
    if (BitCount >= 6) {
      BitCount = 0;
      State = ERROR_DELIM;
    }
  }
  
  else if (State == ERROR_DELIM) {
    BitCount++;
    
    if (val != RECESSIVE) {
      Io_SetValue(CAN_TX, RECESSIVE);
    }
    
    if (BitCount >= 8) {
      BitCount = 0;
      State = INTERFRAME;
    }
  }

  else if (State == INTERFRAME) {
    BitCount++;
    if (BitCount >= 3) {
      //Set the timer to run as fast as possible
      //FastTimer_SetTime(&canReceiveTimer, 1);
      //FastTimer_SetTime(&canReceiveTimer, fastSampleRate);

      BitCount = 0;
      State = IDLE;
    }
  }

  else if (State == UNKNOWN) {
    //Debug(DEBUG_ALWAYS, "*** UNKNOWN State Reached ***\n");
  }
  
}

int Can_InitReceive(void) {
  //Startup interrupt driven receive that triggers on the interval defied by CAN_PERIOD
  FastTimer_SetActive(true);
  fastSampleRate = 540;
  //if (fastSampleRate > CAN_PERIOD) {fastSampleRate = CAN_PERIOD;}
  ////FastTimer_InitializeEntry( &canReceiveTimer, Can_ReceiveIRQCallback, 0, fastSampleRate, true );
  FastTimer_InitializeEntry( &canReceiveTimer, Can_ReceiveIRQCallback, 0, CAN_PERIOD, true );
  ////FastTimer_InitializeEntry( &canReceiveTimer, Can_ReceiveIRQCallback, 0, 1, true );
  FastTimer_Set( &canReceiveTimer ); // start our timer
 
  return 0;
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
  
 
  return CONTROLLER_OK;
}

#ifdef DEBUG_LOCAL
int main() {
  
  Frame frame;
  int i;
  
  init_debug_queue();
  
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
  
  Can_SendData(&frame);
  
  canSendDone = 0;
  printf("canSendLength = %d, canSendI = %d, canSendJ = %d\n", canSendBitLength, canSendI, canSendJ);
  while(!canSendDone) {
    Can_SendIRQCallback(0);
  }
  printf("\n");
  
  
  for(i = 0; i < 150; i++) {
    Can_ReceiveIRQCallback(0);
  }
  printf("Standard = %x, ID = %x, RTR = %x, Data[0] = %x, Data[1] = %x, Data[2] = %x, Data[3] = %x, Data[4] = %x, Data[5] = %x, Data[6] = %x, Data[7] = %x, CRC = %x, Ack = %x, EOF = %x\n", CurrFrame.standard, CurrFrame.identifier1, CurrFrame.rtr, CurrFrame.data[0], CurrFrame.data[1], CurrFrame.data[2], CurrFrame.data[3], CurrFrame.data[4], CurrFrame.data[5], CurrFrame.data[6], CurrFrame.data[7], CurrFrame.crc, CurrFrame.ack, CurrFrame.eof);
  //  Can_PostProcessData();
  
  canSendDone = 0;
  printf("canSendLength = %d, canSendI = %d, canSendJ = %d\n", canSendBitLength, canSendI, canSendJ);
  //while(!canSendDone) {
  //  Can_SendIRQCallback(0);
  //}
  printf("\n");
  

  dump_queue();

  return 0;
}
#endif
