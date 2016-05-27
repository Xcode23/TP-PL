#include "Symbol.h"
#include <stdlib.h>
#include <string.h>

void* cloneVar(void* var){
  VarSymb oldsymb=(VarSymb)var;
  VarSymb newsymb=newVar();
  newsymb->name=strdup(oldsymb->name);
  newsymb->type=strdup(oldsymb->type);
  newsymb->size1=oldsymb->size1;
  newsymb->size2=oldsymb->size2;
  newsymb->location=oldsymb->location;
  return newsymb;
}

void* cloneFunc(void* func){
  FuncSymb oldsymb=(FuncSymb)func;
  FuncSymb newsymb=newFunc();
  newsymb->name=strdup(oldsymb->name);
  newsymb->args=oldsymb->args;
  return newsymb;
}

VarSymb newVar(){
  VarSymb var=(VarSymb)malloc(sizeof(struct _VarSymb_));
  var->name=NULL;
  var->type=NULL;
  return var;
}

FuncSymb newFunc(){
  FuncSymb func=(FuncSymb)malloc(sizeof(struct _FuncSymb_));
  func->name=NULL;
  return func;
}

void eraseVar(VarSymb var){
  free(var->name);
  //free(var->type);
  free(var);
}

void eraseFunc(FuncSymb func){
  free(func->name);
  free(func);
}

int getLocation(htable hashtable,char* key){
  VarSymb var=(VarSymb)get(hashtable,key);
  int location=var->location;
  eraseVar(var);
  return location;
}

int getSize1(htable hashtable,char* key){
  if(!contains(hashtable,key))return 0;
  VarSymb var=(VarSymb)get(hashtable,key);
  int size=var->size1;
  eraseVar(var);
  return size;
}

int getSize2(htable hashtable,char* key){
  if(!contains(hashtable,key))return 0;
  VarSymb var=(VarSymb)get(hashtable,key);
  int size=var->size2;
  eraseVar(var);
  return size;
}

int getArgs(htable hashtable, char* key){
  if(!contains(hashtable,key))return 0;
  FuncSymb func=(FuncSymb)get(hashtable,key);
  int args=func->args;
  eraseFunc(func);
  return args;
}
