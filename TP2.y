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
  int where(char* id,int array,int matrix);
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

Stat    :     Variable '='            {fprintf(output,"pushfp\nswap\n");}
              Exp ';'                 {fprintf(output,"storen\n");}

        |     IF '(' Exp ')'          {push(labelStack,label);
                                       fprintf(output,"jz endif%d\n",label++);}
              '{' StatL '}'           {fprintf(output,"endif%d:nop\n",pop(labelStack));}

        |     WHILE                   {fprintf(output,"startloop%d:nop\n",label);}
              '(' Exp ')'             {push(labelStack,label);
                                       fprintf(output,"jz endloop%d\n",label++);}
              '{' StatL '}'           {fprintf(output, "jump startloop%d\n", aux = pop(labelStack));
                                       fprintf(output,"endloop%d\n",aux);}

        |     WRITE '(' Lexp ')' ';'  {fprintf(output,"writes\n");}

        |     READ '(' Variable ')' ';' {fprintf(output,"pushfp\nswap\nread\natoi\nstoren\n");}
        ;     /*mudar se forem implementados tipos*/

Lexp    :     Lexp ',' STRING         {fprintf(output,"pushs %s\nconcat\n",$3);free($3);}
        |     Lexp ',' Exp            {fprintf(output,"stri\nconcat\n");}
        |     STRING                  {fprintf(output,"pushs %s\n",$1);free($1);}
        |     Exp                     {fprintf(output,"stri\n");}
        ; //cuidado com os tipos

Exp     :     Variable '='            {fprintf(output,"pushfp\nswap\n");}
              Rhs                     {fprintf(output,"dup 3\nstoren\nswap\npop 1\nswap\npop 1\n");}
        |     Rhs
        ;  //cuidado com os tipos

Rhs     :     Rhs '&' Equals          {fprintf(output,"mul\n");}
        |     Rhs '|' Equals          {fprintf(output,"add\n");}
        |     Equals
        ;

Equals  :     Equals EQUAL Differ     {fprintf(output,"equal\n");}
        |     Equals DIFFERENT Differ {fprintf(output,"equal\n");
                                       fprintf(output,"dup 1\nnot\nequal\n");}
        |     Differ
        ;

Differ  :     Differ SE Arit          {fprintf(output,"infeq\n");}
        |     Differ '<' Arit         {fprintf(output,"inf\n");}
        |     Differ GE Arit          {fprintf(output,"supeq\n");}
        |     Differ '>' Arit         {fprintf(output,"sup\n");}
        |     Arit
        ;

Arit    :     Arit '+' Term           {fprintf(output,"add\n");}
        |     Arit '-' Term           {fprintf(output,"sub\n");}
        |     Term
        ;

Term    :     Term '*' Factor         {fprintf(output,"mul\n");}
        |     Term '/' Factor         {fprintf(output,"div\n");}
        |     Term '%' Factor         {fprintf(output,"mod\n");}
        |     Factor
        ;

Factor  :     '!' Value               {fprintf(output,"dup 1\nnot\nequal\n");}
        |     '-' Value               {fprintf(output,"pushi 0\nswap\nsub\n");}
        |     Value
        ;

Value   :     INT                     {fprintf(output,"pushi %d\n",$1);}
        |     Variable                {fprintf(output,"pushfp\nswap\nloadn\n");}
        |     '(' Exp ')'
        ;

Variable:     ID                      {fprintf(output,"pushi %d\n",where($1,0,0));free($1);}
        |     ID '[' Exp ']'          {fprintf(output,"pushi %d\nadd\n",where($1,1,0));free($1);}
        |     ID '[' Exp ']' '[' Exp ']'{fprintf(output,"pushi %d\nmul\nadd\n",getSize1(varSymT,$1));
                                         fprintf(output,"pushi %d\nadd\n",where($1,1,1));free($1);}
        ;
%%

int where(char* id,int array,int matrix){
  int loc=-1;
  VarSymb aux;
  if(!contains(varSymT,id))
    yyerror("Variable not declared");
  else{
    if((!array==!getSize1(varSymT,id))&&(!matrix==!getSize2(varSymT,id)))
      loc=getLocation(varSymT,id);
    else
      yyerror("inappropriate variable access");
    }
  return loc;
}

void declaration(char* id, int size1, int size2){
  if(contains(varSymT,id))yyerror("Variable declared twice");
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
  fprintf(output,"stop\n");

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
