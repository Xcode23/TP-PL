%{
  #include <stdio.h>
  #include "lib/Symbol.h"
  #include "lib/Stack.h"

  void yyerror (char const *s);
  extern int yylex();
  extern int yylineno;
  extern char* yytext;
  extern FILE * yyin;
  FILE* output;
  htable varSymT;
  Stack labelStack;
  int location=0;
  int err=0;
  int label=1;
  int aux=0;

  void declaration(char* id, int size1, int size2);
%}

%union{
  int ivalue;
  char* string;
}

%start Prog

%type <ivalue> INT Variable
%type <string> ID STRING

%token DECLS STATS STRING INT ID IF WHILE WRITE READ EQUAL DIFFERENT GE SE ERROR
%%

Prog    :     DeclL STATS StatL /*no endmarker*/
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

StatL   :     StatL Stat
        |     Stat
        ;

Stat    :     Variable '=' Exp ';'    {fprintf(output,"storel %d\n",$1);}

        |     IF '(' Exp ')'          {push(labelStack,label);
                                       fprintf(output,"jz endif%d\n",label++);}
              '{' StatL '}'           {fprintf(output,"endif%d:nop\n",pop(labelStack));}

        |     WHILE                   {fprintf(output,"startloop%d:nop\n",label);}
              '(' Exp ')'             {push(labelStack,label);
                                       fprintf(output,"jz endloop%d\n",label++);}
              '{' StatL '}'           {fprintf(output, "jump startloop%d\n", aux = pop(labelStack));
                                       fprintf(output,"endloop%d\n",aux);}

        |     WRITE '(' Lexp ')' ';'  {fprintf(output,"writes\n");}

        |     READ '(' Variable ')' ';' {fprintf(output,"read\natoi\nstorel %d\n",$3);}
        ;

Lexp    :     Lexp ',' STRING
        |     Lexp ',' Exp
        |     STRING
        |     Exp
        ;

Exp     :     Exp '&' Equals/*must be in stack by the end*/
        |     Exp '|' Equals
        |     Equals
        ;

Equals  :     Equals EQUAL Differ
        |     Equals DIFFERENT Differ
        |     Differ
        ;

Differ  :     Differ SE Arit
        |     Differ '<' Arit
        |     Differ GE Arit
        |     Differ '>' Arit
        |     Arit
        ;

Arit    :     Arit '+' Term
        |     Arit '-' Term
        |     Term
        ;

Term    :     Term '*' Factor
        |     Term '/' Factor
        |     Term '%' Factor
        |     Factor
        ;

Factor  :     '!' Value
        |     '-' Value
        |     Value
        ;

Value   :     INT
        |     Variable
        |     '(' Exp ')'
        ;

Variable:     ID/*return offset*/
        |     ID '[' Exp ']'
        |     ID '[' Exp ']' '[' Exp ']'
        ;
%%

void declaration(char* id, int size1, int size2){
  if(contains(varSymT,id))yyerror("Variable declared twice");
  else{
    VarSymb* var=newVar();
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

void yyerror (char const *s){
  fprintf(stderr,"%d: %s at %s\n", yylineno, s, yytext);
  err=1;
}

int main(int argc, char** argv){
  varSymT=newTable(hashString,equalsString,cloneString,cloneVar);
  labelStack=newStack();
  if(argc<2 || argc>3){
    printf("Número errado de argumentos!\n");
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

  fprintf(output,"start\n");/******remember to move if functions are implemented******/
  yyparse();

  deleteHtable(varSymT);   //cleanup
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
