%{
  #include "y.tab.h"
  #include <string.h>
  #define CBRACK '}'

%}

%option yylineno
%%

if              return IF;
else            return ELSE;
while           return WHILE;
read            return READ;
write           return WRITE;
decls           return DECLS;
stats           return STATS;
def             return DEF;
return          return RETURN;
main            return MAIN;
\+              return '+';
\-              return '-';
\*              return '*';
\/              return '/';
\%              return '%';
\<              return '<';
\>              return '>';
\=              return '=';
\,              return ',';
\;              return ';';
\(              return '(';
\)              return ')';
\{              return '{';
\}              return CBRACK;
\[              return '[';
\]              return ']';
\!              return '!';
\&              return '&';
\|              return '|';
\<\=            return SE;
\>\=            return GE;
\=\=            return EQUAL;
\!\=            return DIFFERENT;
\#              return '#';
[0-9]+          {yylval.ivalue=atoi(yytext);return INT;}

\"(\\.|[^\\"])*\" {yylval.string=strdup(yytext);return STRING;}

[a-zA-Z_][a-zA-Z_0-9]* {yylval.string=strdup(yytext);return ID;}

[ \t\n]+        ;

.               return ERROR;
%%
