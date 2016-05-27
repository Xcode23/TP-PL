#include "Stack.h"
#include <stdlib.h>

typedef struct _node_{
  int num;
  struct _node_ *next;
}*Node;

struct _stack_{
  Node top;
};

struct _StateStack_{
  State top;
};

Stack newStack(){
  Stack newstack=(Stack)malloc(sizeof(struct _stack_));
  newstack->top=NULL;
  return newstack;
}
SStack newSStack(){
  SStack newstack=(SStack)malloc(sizeof(struct _StateStack_));
  newstack->top=NULL;
  return newstack;
}

void sPush(SStack stack, htable table){
  State newState=(State)malloc(sizeof(struct _state_));
  newState->table=table;
  newState->next=stack->top;
  stack->top=newState;
}

void push(Stack stack,int value){
  Node newnode=(Node)malloc(sizeof(struct _node_));
  newnode->num=value;
  newnode->next=stack->top;
  stack->top=newnode;
}

htable sPop(SStack stack){
  if(!stack->top)return NULL;
  htable table;
  State state=stack->top;
  stack->top=state->next;
  table=state->table;
  free(state);
  return table;
}

int pop(Stack stack){
  Node node;
  int ret;
  if(!stack->top)return 0;
  node=stack->top->next;
  ret=stack->top->num;
  free(stack->top);
  stack->top=node;
  return ret;
}
