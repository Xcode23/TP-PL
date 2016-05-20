#include "Stack.h"
#include <stdlib.h>

typedef struct _node_{
  int num;
  struct _node_ *next;
}*Node;

struct _stack_{
  Node top;
};

Stack newStack(){
  Stack newstack=(Stack)malloc(sizeof(struct _node_));
  newstack->top=NULL;
  return newstack;
}

void push(Stack stack,int value){
  Node newnode=(Node)malloc(sizeof(struct _node_));
  newnode->num=value;
  newnode->next=stack->top;
  stack->top=newnode;
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
