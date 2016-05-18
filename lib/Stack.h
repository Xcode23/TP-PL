#ifndef STACK
#define STACK

typedef struct _stack_ *Stack;

Stack newStack();
void push(Stack stack,int value);
int pop(Stack stack);


#endif
