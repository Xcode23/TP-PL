%{
  #include <stdio.h>
  #include "lib/Symbol.h"
  #include "lib/Stack.h"

  void yyerror (char const *s);
  extern int yylex();
  extern int yylineno;
  extern FILE * yyin;
  FILE* output;
  htable funcTable;
  htable varSymT;
  htable globalSymT;
  Stack labelStack;
  SStack funcStack;
  int location=0;
  int err=0;
  int label=1;
  int aux=0;
  int maindec=0;
  int global=0;
  int size=0;

  void declaration(char* id, int size1, int size2);
  int where(char* id,int array,int matrix);
  void funcDeclaration(char* func, int argc);
  void funcCall(char* func, int argc);
  void argDeclaration(char* id, int size1, int size2);
%}

%union{
  int ivalue;
  char* string;
}

%start Prog

%type <ivalue> INT Variable ArgS Args ArgLists ArgList
%type <string> ID STRING

%token DECLS STATS STRING INT ID IF WHILE WRITE READ EQUAL DIFFERENT GE SE DEF RETURN MAIN ELSE ERROR
%%

Prog    :     DeclL                       {globalSymT=varSymT;
                                           fprintf(output,"start\npusha main\ncall\nnop\njump end\n");}
              FuncList /*no endmarker*/   {fprintf(output,"end:nop\n");}
        ;

DeclL   :     DECLS Decls ';'
        |
        ;

Decls   :     Decls ',' Decl
        |     Decl
        ;

Decl    :     ID '[' INT ']'              {declaration($1,$3,0);}
        |     ID '[' INT ']' '[' INT ']'  {declaration($1,$3,$6);}
        |     ID                          {declaration($1,0,0);}
        ;

FuncList:     FuncList Func
        |     Func
        ;

Func    :     DEF ID                      {varSymT=newTable(hashString,equalsString,cloneString,cloneVar);
                                           location=0;}

              '(' ArgS ')'                {funcDeclaration($2,$5);
                                           fprintf(output,"dup %d\n",$5);
                                           fprintf(output,"pushi 0\nstoreg 0\n");}

              '{'DeclL STATS StatL'}'     {fprintf(output,"return\n");
                                           deleteHtable(varSymT);
                                           //varSymT=sPop(funcStack);
                                          }

        |     DEF MAIN                    {if(!maindec){
                                              maindec++;
                                              fprintf(output,"main:nop\n");
                                            }
                                           else yyerror("main declared more than once");
                                           varSymT=newTable(hashString,equalsString,cloneString,cloneVar);
                                           location=0;}

              '{' DeclL STATS StatL'}'    {fprintf(output,"return\n");deleteHtable(varSymT);}
        ;

ArgS    :     Args
        |                                 {$$=0;}
        ;

Args    :     Args ',' ID                 {$$=$1+1;argDeclaration($3,0,0);}
        |     ID                          {$$=1;argDeclaration($1,0,0);}
        ;

StatL   :     StatL Stat
        |     Stat
        ;

Stat    :     Variable                    {if(global)fprintf(output,"pushgp\nswap\n");
                                           else fprintf(output,"pushfp\nswap\n");}
              '=' Exp ';'                 {fprintf(output,"storen\n");}

        |     IF '(' Exp ')'              {push(labelStack,label);
                                           fprintf(output,"jz endif%d\n",label++);}
              '{' StatL '}'               {aux=pop(labelStack);
                                           fprintf(output,"jump endelse%d\nendif%d:nop\n",aux,aux);
                                           push(labelStack,aux);}
              Elsebranch

        |     WHILE                       {fprintf(output,"startloop%d:nop\n",label);}
              '(' Exp ')'                 {push(labelStack,label);
                                           fprintf(output,"jz endloop%d\n",label++);}
              '{' StatL '}'               {aux = pop(labelStack);
                                           fprintf(output, "jump startloop%d\n", aux);
                                           fprintf(output,"endloop%d:nop\n",aux);}

        |     WRITE '(' Lexp ')' ';'      {fprintf(output,"writes\n");}

        |     READ '(' Variable ')' ';'   {if(global)fprintf(output,"pushgp\nswap\nread\natoi\nstoren\n");
                                           else fprintf(output,"pushfp\nswap\nread\natoi\nstoren\n");}

        |     ID'(' ArgLists ')' ';'   {funcCall($1,$3);
                                           fprintf(output,"pop %d\n",$3);
                                           //sPush(funcStack,varSymT);
                                          }

        |     RETURN Exp ';'              {fprintf(output,"storeg 0\nreturn\n");}
        ;     /*mudar se forem implementados tipos*/

Elsebranch:   ELSE '{'StatL'}'            {fprintf(output,"endelse%d:nop\n",pop(labelStack));}
          |                               {fprintf(output,"endelse%d:nop\n",pop(labelStack));}
          ;

ArgLists:     ArgList
        |                                 {$$=0;}
        ;

ArgList :     ArgList ',' Exp             {$$=$1+1;}
        |     Exp                         {$$=1;}
        ;

Lexp    :     Lexp ',' STRING             {fprintf(output,"pushs %s\nconcat\n",$3);free($3);}
        |     Lexp ',' Exp                {fprintf(output,"stri\nconcat\n");}
        |     STRING                      {fprintf(output,"pushs %s\n",$1);free($1);}
        |     Exp                         {fprintf(output,"stri\n");}
        ; //cuidado com os tipos

Exp     :     Variable '='                {if(global)fprintf(output,"pushgp\nswap\n");
                                           else fprintf(output,"pushfp\nswap\n");}
              Rhs                         {fprintf(output,"dup 3\nstoren\nswap\npop 1\nswap\npop 1\n");}
        |     Rhs
        ;  //cuidado com os tipos

Rhs     :     Rhs '&' Equals              {fprintf(output,"mul\n");}
        |     Rhs '|' Equals              {fprintf(output,"add\n");}
        |     Equals
        ;

Equals  :     Equals EQUAL Differ         {fprintf(output,"equal\n");}
        |     Equals DIFFERENT Differ     {fprintf(output,"equal\n");
                                           fprintf(output,"dup 1\nnot\nequal\n");}
        |     Differ
        ;

Differ  :     Differ SE Arit              {fprintf(output,"infeq\n");}
        |     Differ '<' Arit             {fprintf(output,"inf\n");}
        |     Differ GE Arit              {fprintf(output,"supeq\n");}
        |     Differ '>' Arit             {fprintf(output,"sup\n");}
        |     Arit
        ;

Arit    :     Arit '+' Term               {fprintf(output,"add\n");}
        |     Arit '-' Term               {fprintf(output,"sub\n");}
        |     Term
        ;

Term    :     Term '*' Factor             {fprintf(output,"mul\n");}
        |     Term '/' Factor             {fprintf(output,"div\n");}
        |     Term '%' Factor             {fprintf(output,"mod\n");}
        |     Factor
        ;

Factor  :     '!' Value                   {fprintf(output,"dup 1\nnot\nequal\n");}
        |     '-' Value                   {fprintf(output,"pushi 0\nswap\nsub\n");}
        |     Value
        ;

Value   :     INT                         {fprintf(output,"pushi %d\n",$1);}
        |     Variable                    {if(global)fprintf(output,"pushgp\nswap\nloadn\n");
                                           else fprintf(output,"pushfp\nswap\nloadn\n");}
        |     ID '('ArgLists')'       {funcCall($1,$3);
                                           fprintf(output,"pop %d\npushg 0\n",$3);
                                           //sPush(funcStack,varSymT);
                                          }
        |     '(' Exp ')'
        ;

Variable:     ID                          {fprintf(output,"pushi %d\n",where($1,0,0));free($1);}
        |     ID '[' Exp ']'              {fprintf(output,"pushi %d\nadd\n",where($1,1,0));free($1);}
        |     ID '[' Exp ']' '[' Exp ']'  {size=getSize1(varSymT,$1);
                                           if(!size){
                                             size=getSize1(globalSymT,$1);
                                           }
                                           fprintf(output,"pushi %d\nmul\nadd\n",size);
                                           fprintf(output,"pushi %d\nadd\n",where($1,1,1));free($1);}
        ;
%%

int getSize(char* key){
  int size=0;
  size=getSize1(varSymT,$1);
  if(!size)
    size=getSize1(globalSymT,$1);
  return size;
}

int where(char* id,int array,int matrix){
  int loc=-1;
  VarSymb aux;
  if(!contains(varSymT,id)){
    if(!contains(globalSymT,id))yyerror("Variable not declared");
    else{
      if((!array==!getSize1(globalSymT,id))&&(!matrix==!getSize2(globalSymT,id))){
        loc=getLocation(globalSymT,id);
        global=1;
      }
      else
        yyerror("Inappropriate access to global variable");
    }
  }
  else{
    if((!array==!getSize1(varSymT,id))&&(!matrix==!getSize2(varSymT,id))){
      loc=getLocation(varSymT,id);
      global=0;
    }
    else
      yyerror("Inappropriate access to local variable");
  }
  return loc;
}

void funcCall(char* func, int argc){
  if(!contains(funcTable,func))yyerror("Function not declared");
  else{
    if(getArgs(funcTable,func)!=argc)yyerror("Incorrect number of arguments in function call");
    else fprintf(output,"pusha %s\ncall\nnop\n",func);
  }
}

void funcDeclaration(char* func, int argc){
  if(contains(funcTable,func))yyerror("Function declared more than once");
  else{
    FuncSymb newfunc=newFunc();
    newfunc->name=func;
    newfunc->args=argc;
    put(funcTable,func,newfunc);
    fprintf(output,"%s:nop\n",func);
    eraseFunc(newfunc);
  }
}

void declaration(char* id, int size1, int size2){
  if(contains(varSymT,id))yyerror("Variable declared more than once");
  else{
    VarSymb var=newVar();
    var->name=id;
    var->type="int";
    var->size1=size1;
    var->size2=size2;
    var->location=location;
    if(size1==0)size1++;
    if(size2==0)size2++;
    location+=size1*size2;
    put(varSymT,id,var);
    eraseVar(var);
    fprintf(output, "pushn %d\n", size1*size2);
  }
}

void argDeclaration(char* id, int size1, int size2){
  if(contains(varSymT,id))yyerror("Variable declared more than once");
  else{
    VarSymb var=newVar();
    var->name=id;
    var->type="int";
    var->size1=size1;
    var->size2=size2;
    var->location=location;
    if(size1==0)size1++;
    if(size2==0)size2++;
    location+=size1*size2;
    put(varSymT,id,var);
    eraseVar(var);
  }
}

void yyerror (char const *s){
  fprintf(stderr,"%d: %s\n", yylineno, s);
  err=1;
}

void otherError(char const *s){
  fprintf(stderr,"Error: %s\n",s);
  err=1;
}

int main(int argc, char** argv){
  varSymT=newTable(hashString,equalsString,cloneString,cloneVar);
  funcTable=newTable(hashString,equalsString,cloneString,cloneFunc);
  labelStack=newStack();
  funcStack=newSStack();
  if(argc<2 || argc>3){
    printf("Incorrect number of arguments\n");
    return -1;
  }
  if(argc==2){
    yyin=fopen(argv[1],"r");
    output=fopen("output","w");
  }
  if(argc==3){
    yyin=fopen(argv[1],"r");
    output=fopen(argv[2],"w");
  }
  fprintf(output,"pushi 0\n");
  location++;
  yyparse();
  fprintf(output,"stop\n");

  if(!maindec)otherError("main not declared");
   //cleanup
  deleteHtable(globalSymT);
  while(pop(labelStack));
  free(labelStack);

  fclose(yyin);
  fclose(output);
  if(err){
    if(argc==3)
      remove(argv[2]);
    else
      remove("output");
  }
  return 0;
}
