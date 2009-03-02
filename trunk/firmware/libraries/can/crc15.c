#include <stdio.h>
#include <string.h>

// CRC parameters (default values are for CRC-32):

const int order = 15;
const unsigned long polynom = 0x4599;
const int direct = 1;
const unsigned long crcinit = 0x00000000;
const unsigned long crcxor = 0x00000000;
const int refin = 0;
const int refout = 0;

// 'order' [1..32] is the CRC polynom order, counted without the leading '1' bit
// 'polynom' is the CRC polynom without leading '1' bit
// 'direct' [0,1] specifies the kind of algorithm: 1=direct, no augmented zero bits
// 'crcinit' is the initial CRC value belonging to that algorithm
// 'crcxor' is the final XOR value
// 'refin' [0,1] specifies if a data byte is reflected before processing (UART) or not
// 'refout' [0,1] specifies if the CRC will be reflected before XOR


// Data character string

const unsigned char string[] = {"123456789"};

// internal global values:

unsigned long crcmask;
unsigned long crchighbit;
unsigned long crcinit_direct;
unsigned long crcinit_nondirect;
unsigned long crctab[256];

unsigned long reflect (unsigned long crc, int bitnum) {

	// reflects the lower 'bitnum' bits of 'crc'

	unsigned long i, j=1, crcout=0;

	for (i=(unsigned long)1<<(bitnum-1); i; i>>=1) {
		if (crc & i) crcout|=j;
		j<<= 1;
	}
	return (crcout);
}

unsigned long crcbitbybit(unsigned char* p, unsigned long len) {

  // bit by bit algorithm with augmented zero bytes.
  // does not use lookup table, suited for polynom orders between 1...32.

  unsigned long i, j, c, bit;
  unsigned long crc = crcinit_nondirect;

  for (i=0; i<len; i++) {

    c = (unsigned long)*p++;
    printf("c = %d\n", c);
    if (refin) c = reflect(c, 8);

    for (j=0x80; j; j>>=1) {

      bit = crc & crchighbit;
      printf("bit = %d\n", bit);
      crc<<= 1;
      if (c & j) crc|= 1;
      if (bit) crc^= polynom;
      printf("crc = %x\n", crc);
    }
  }	

  for (i=0; i<order; i++) {

    bit = crc & crchighbit;
    crc<<= 1;
    if (bit) crc^= polynom;
    printf("crc = %x\n", crc);
    
  }

  if (refout) crc=reflect(crc, order);
  crc^= crcxor;
  crc&= crcmask;

  return(crc);
}



void hex2bin(unsigned int num, char* val) {
  int i;

  for (i = 0; i < 32; i++) {
    if (num & 0x80000000) {
      val[i] = '1';
    } else {
      val[i] = '0';
    }
    num = num << 1;
  }
  val[33] = '\0';
}

unsigned int bin2hex(char* bin, int length) {
  unsigned int val;
  int i;

  val = 0;

  for (i = 0; i < length; i++) {
    if (bin[i] == '1') {
      val = val | (1 << (length - i - 1));
    }
  }
  
  return val;
}

void xorstring(char* str1, char* str2) {
  int i;

  printf("str before = %s\n", str1);
  if (str1[0] == '1') {
    printf("xor        = %s\n", str2);
    for (i = 0; i < 15; i++) {
      if (str1[i] == '1' && str2[i] == '1') {
	str1[i] = '0';
      }
      else if (str1[i] == '1' && str2[i] == '0') {
	str1[i] = '1';
      }
      else if (str1[i] == '0' && str2[i] == '1') {
	str1[i] = '1';
      }
      else {
	str1[i] = '0';
      }
    }
  } else {
    printf("xor        = %s\n", "000000000000000");
  }
  printf("str after  = %s\n", str1);

}


int main() {
  unsigned int a = 0xFFFFFFFF;
  unsigned int crc15div = 0x62CC;
  char* crc15 = "110001011001100";
  char* bin;
  int i;
  unsigned int final;

  bin = malloc(sizeof(char) * 33);
  hex2bin(a, bin);

  printf("Num = %s\n", bin);
  
  for(i = 0; i < 32-15; i++) {
    xorstring(bin, crc15);
    printf("%s\n", bin);
    bin = bin + 1;
  }
  printf("%s\n", bin);
  
  final = bin2hex(bin, 15);
  printf("Final = 0x%08X\n", final);



  /////////////

  printf("\n===========================================\n\n");
  {
    crcmask = ((((unsigned long)1<<(order-1))-1)<<1)|1;
    crchighbit = (unsigned long)1<<(order-1);
    

    char bits[8];
    bits[0] = 0x12;
    bits[1] = 0x34;
    bits[2] = 0x56;
    bits[3] = 0x78;
    
    final = crcbitbybit(bits, 4);
    printf("Final2 = 0x%08X\n", final);
  }

  return 0;
}

