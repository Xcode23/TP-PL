#ifndef HASHT
#define HASHT

typedef struct _hashtable_ htable;

htable* newTable(unsigned long (*hashfunc)(void*), int (*equalsfunc)(void*,void*), void* (*clonekeyfunc)(void*), void* (*clonevaluefunc)(void*));//create HashTable
void deleteHtable(htable* hashtable);//Destroy HashTable

void* put(htable* hashtable, void* key, void* value);//insert key-value pair
void* get(htable* hashtable,void* key);//get value from key
int contains(htable* hashtable,void* key);//verify if key exists in HashTable
void removePair(htable* hashtable,void* key);//remove from HashTable key-value pair


unsigned long hashString(void* voidkey);//provided string hashing function
unsigned long hashInt(void* voidkey);//provided integer hashing function
void* cloneString(void* str);//provided string cloning function
void* cloneInt(void* integer);//provided integer cloning function
int equalsString(void* str1, void* str2);//provided string equals function
int equalsInt(void* int1, void* int2);//provided integer equals function


#endif
