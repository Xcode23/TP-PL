#ifndef STACK
#define STACK
#include "HashT.h"

typedef struct _stack_ *Stack;
typedef struct _state_{
  htable table;
  struct _state_ *next;
}*State;
typedef struct _StateStack_ *SStack;

Stack newStack();
void push(Stack stack,int value);
int pop(Stack stack);
htable sPop(SStack stack);
void sPush(SStack stack, htable table);
SStack newSStack();


#endif
