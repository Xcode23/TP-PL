%{
  #include "lib/HashT.h"
  #include <stdio.h>

  void yyerror (char const *s);
  extern int yylex();
%}

%union{
  int ivalue;
  char* string;
}

%token DECLS STATS STRING INT ID IF WHILE WRITE READ EQUAL DIFFERENT GE SE ERROR
%%
Prog:   DeclL STATS StatL '$';

DeclL:  DECLS Decls ';'
     |  ;

Decls:  Decls ',' Decl
     |  Decl;

Decl:   ID '[' INT ']'
    |   ID '[' INT ']'  '[' INT ']'
    |   ID;

StatL:  StatL Stat';'
     |  Stat ';';

Stat:   Variable '=' Exp
    |   IF '(' Exp ')'  '{' StatL '}'
    |   WHILE '(' Exp ')'  '{' StatL '}'
    |   WRITE '(' Lexp ')'
    |   READ '(' Variable ')';

Lexp:   Lexp ',' STRING
    |   Lexp ',' Exp
    |   STRING
    |   Exp;

Exp:    Exp '&' Equals
   |    Exp '|' Equals
   |    Equals;

Equals: Equals EQUAL Differ
      | Equals DIFFERENT Differ
      | Differ;

Differ: Differ SE Arit
      | Differ '<' Arit
      | Differ GE Arit
      | Differ '>' Arit
      | Arit;

Arit:   Arit '+' Term
    |   Arit '-' Term
    |   Term;

Term:   Term '*' Factor
    |   Term '/' Factor
    |   Term '%' Factor
    |   Factor;

Factor: '!' Value
      | '-' Value
      | Value;

Value:  INT
     |  Variable
     |  '#' ID;

Variable:
        ID
      | ID '[' Exp ']'
      | ID '[' Exp ']' '[' Exp ']' ;
%%

void yyerror (char const *s)
{
  fprintf (stderr, "%s\n", s);
}

int main(int argc, char** argv){
  return 0;
}
