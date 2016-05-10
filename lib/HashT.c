#include <stdlib.h>
#include <string.h>
#include "HashT.h"
#include <stdio.h>

#define STARTINGSIZE 16
#define LOADFACTOR 0.7
#define HASH(hashtable,key) ({(hashtable->hashcode(key))%(hashtable->size);})


typedef struct _node_{
  void* key;
  void* value;
  struct _node_* next;
}node;

struct _hashtable_{
  unsigned long int (*hashcode)(void*);
  int (*equals)(void*,void*);
  void* (*clonekey)(void*);
  void* (*clonevalue)(void*);
  int size;
  int used;
  node** table;
};

htable* newTable(unsigned long (*hashfunc)(void*), int (*equalsfunc)(void*,void*), void* (*clonekeyfunc)(void*), void* (*clonevaluefunc)(void*)){
  htable* newtable;
  int i;

  if(hashfunc==NULL || equalsfunc==NULL || clonekeyfunc==NULL || clonevaluefunc==NULL)
    return NULL;

  if(!(newtable=(htable*)malloc(sizeof(htable))))
    return NULL;

  newtable->hashcode=hashfunc;
  newtable->equals=equalsfunc;
  newtable->clonekey=clonekeyfunc;
  newtable->clonevalue=clonevaluefunc;
  newtable->size=STARTINGSIZE;
  newtable->used=0;
  if(!(newtable->table=(node**)malloc(newtable->size*sizeof(node*))))
    return NULL;

  for(i=0;i<newtable->size;i++)newtable->table[i]=NULL;

  return newtable;
}

void erasenode(node* oldnode){
  if(oldnode!=NULL){
    free(oldnode->key);
    free(oldnode->value);
    free(oldnode);
  }
}

void eraselist(node* oldlist){
  node* next;
  while(oldlist!=NULL){
    next=oldlist->next;
    erasenode(oldlist);
    oldlist=next;
  }
}

node** createTable(int size){
  int i;
  node** auxtable=(node**)malloc(size*sizeof(node*));
  for(i=0;i<size;i++)auxtable[i]=NULL;
  return auxtable;
}

node* createNode(){
  node* auxnode=(node*)malloc(sizeof(node));
  auxnode->key=NULL;
  auxnode->value=NULL;
  auxnode->next=NULL;
  return auxnode;
}

void deleteHtable(htable* hashtable){
  int i;
  if(hashtable==NULL)return;
  for(i=0;i<hashtable->size;i++)
    eraselist(hashtable->table[i]);
  free(hashtable->table);
  free(hashtable);
}

void* get(htable* hashtable,void* key){
  int location;
  node* auxnode;
  if(hashtable==NULL)return NULL;
  if(key==NULL)return NULL;

  location=HASH(hashtable,key);
  auxnode=hashtable->table[location];

  if(auxnode==NULL)return NULL;
  while(auxnode){
    if(hashtable->equals(auxnode->key,key))return hashtable->clonevalue(auxnode->value);
    auxnode=auxnode->next;
  }
  return NULL;
}

htable* resize(htable* hashtable){
  node **newtable, **oldtable, *auxnode;
  oldtable=hashtable->table;
  int i,oldsize=hashtable->size;

  hashtable->size=hashtable->size*2;
  if(!(newtable=createTable(hashtable->size)))
    return NULL;

  hashtable->table=newtable;
  hashtable->used=0;


  for(i=0;i<oldsize;i++){
    if(oldtable[i]){
      auxnode=oldtable[i];
      while(auxnode!=NULL){
        put(hashtable,auxnode->key,auxnode->value);
        auxnode=auxnode->next;
      }
      eraselist(oldtable[i]);
    }
  }

  free(oldtable);
  return hashtable;
}

int contains(htable* hashtable,void* key){
  int location;
  node* auxnode;

  if(!hashtable)return 0;
  if(!key)return 0;

  location=HASH(hashtable,key);
  auxnode=hashtable->table[location];

  if(auxnode==NULL)return 0;
  while(auxnode){
    if(hashtable->equals(auxnode->key,key))return 1;
    auxnode=auxnode->next;
  }
  return 0;
}

void removePair(htable* hashtable,void* key){
  int location;
  node *prev=NULL, *auxnode;

  if(!key)return;
  if(!hashtable)return;

  location=HASH(hashtable,key);
  auxnode=hashtable->table[location];

  if(auxnode==NULL)return;
  while(auxnode){
    if(hashtable->equals(auxnode->key,key)){
      if(!prev)
        hashtable->table[location]=auxnode->next;
      else
        prev->next=auxnode->next;

      erasenode(auxnode);
      hashtable->used--;
      break;
    }
    else{
      prev=auxnode;
      auxnode=auxnode->next;
    }
  }
}

void* put(htable* hashtable, void* key, void* value){
  int location,equal=0;
  node *auxnode, *newnode;

  if(key==NULL||value==NULL||hashtable==NULL)return NULL;

  key=hashtable->clonekey(key);
  value=hashtable->clonevalue(value);

  if((float)hashtable->used/(float)hashtable->size>LOADFACTOR)
    if(!resize(hashtable))return NULL;

  location=HASH(hashtable,key);

  if(location<0)return NULL;

  if(!(newnode=createNode()))
    return NULL;

  newnode->key=key;
  newnode->value=value;
  if(hashtable->table[location]==NULL){
    hashtable->table[location]=newnode;
  }
  else{
    if(hashtable->equals(hashtable->table[location]->key,key)){
      newnode->next=hashtable->table[location]->next;
      erasenode(hashtable->table[location]);
      hashtable->table[location]=newnode;
    }
    else{
      auxnode=hashtable->table[location];
      while(auxnode->next){
        equal=hashtable->equals(auxnode->next->key,key);
        if(equal)break;
        auxnode=auxnode->next;
      }

      if(equal){
        newnode->next=auxnode->next->next;
        erasenode(auxnode->next);
        hashtable->used--;
      }
      auxnode->next=newnode;
    }
  }
  hashtable->used++;

  return value;
}


unsigned long hashString(void* voidkey){/*djb2 hash function"*/
  unsigned long hash = 5381;
  char* key=(char*)voidkey;
  int c = *key++;

  while(c){
    hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    c = *key++;
  }


  return hash;
}

unsigned long hashInt(void* voidkey){//robert jenkins hash
  int* key=(int*)voidkey;
  unsigned long a=*key;
  a = (a+0x7ed55d16) + (a<<12);
  a = (a^0xc761c23c) ^ (a>>19);
  a = (a+0x165667b1) + (a<<5);
  a = (a+0xd3a2646c) ^ (a<<9);
  a = (a+0xfd7046c5) + (a<<3);
  a = (a^0xb55a4f09) ^ (a>>16);
  return a;
}

void* cloneString(void* str){
  char* string=(char*)str;
  char* newstr=strdup(string);
  return (void*)newstr;
}

void* cloneInt(void* integer){
  int* copy=(int*)malloc(sizeof(int));
  int* original=(int*)integer;
  *copy = *original;
  return (void*)copy;
}

int equalsString(void* str1, void* str2){
  if(!strcmp((char*)str1,(char*)str2))return 1;
  else return 0;
}

int equalsInt(void* int1, void* int2){
  int* a=(int*)int1;
  int* b=(int*)int2;
  if(*a == *b)return 1;
  else return 0;
}

int giveSize(htable* hashtable){
  return hashtable->size;
}

int giveUsed(htable* hashtable){
  return hashtable->used;
}
