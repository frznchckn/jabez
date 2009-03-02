#ifndef CAN_H
#define CAN_H

typedef enum {DOMINANT = 0, RECESSIVE = 1} BIT_TYPE;

typedef struct {
  unsigned int standard : 1;
  unsigned int identifier1 : 11;
  unsigned int identifier2 : 18;
  unsigned int rtr : 1;
  unsigned int dlc : 4;
  unsigned char data[8];
  unsigned int crc : 16;
  unsigned int ack : 2;
  unsigned int eof : 7;
} Frame;



int Can_SetActive( int state );
int Can_GetActive(void);
int Can_Start(void);
int Can_Stop(void);
int Can_Init(void);
int Can_SendData(Frame frame);
int Can_ReceiveData(unsigned int* data);

/* OSC Interface */
const char* CanOsc_GetName( void );
int CanOsc_ReceiveMessage( int channel, char* message, int length );


#endif
