#ifndef SYMB
#define SYMB

#include "HashT.h"

typedef struct _VarSymb_{
  char* name;
  char* type;
  int size1;
  int size2;
  int location;
}*VarSymb;

typedef struct _FuncSymb_{
  char* name;
  int args;
}*FuncSymb;

void* cloneVar(void* var);
VarSymb newVar();
void eraseVar(VarSymb var);
int getLocation(htable hashtable,char* key);
int getSize1(htable hashtable,char* key);
int getSize2(htable hashtable,char* key);

void* cloneFunc(void* func);
FuncSymb newFunc();
void eraseFunc(FuncSymb func);
int getArgs(htable hashtable, char* key);

#endif
