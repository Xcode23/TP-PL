#ifndef SYMB
#define SYMB

#include "HashT.h"

typedef struct _VarSymb_{
  char* name;
  char* type;
  int size1;
  int size2;
  int location;
}VarSymb;

void* cloneVar(void* var);
VarSymb* newVar();
void eraseVar(VarSymb* var);
int getLocation(htable* hashtable,char* key);
int getSize1(htable* hashtable,char* key);
int getSize2(htable* hashtable,char* key);

#endif
