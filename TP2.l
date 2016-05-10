%{
  #include "y.tab.h"
  #include <string.h>
  #define CBRACK '}'

  void count();
  int line=1,column=1;
%}

%%

if              {count();return IF;}
while           {count();return WHILE;}
read            {count();return READ;}
write           {count();return WRITE;}
decls           {count();return DECLS;}
stats           {count();return STATS;}
\+              {count();return '+';}
\-              {count();return '-';}
\*              {count();return '*';}
\/              {count();return '/';}
\%              {count();return '%';}
\<              {count();return '<';}
\>              {count();return '>';}
\=              {count();return '=';}
\,              {count();return ',';}
\;              {count();return ';';}
\(              {count();return '(';}
\)              {count();return ')';}
\{              {count();return '{';}
\}              {count();return CBRACK;}
\[              {count();return '[';}
\]              {count();return ']';}
\!              {count();return '!';}
\&              {count();return '&';}
\|              {count();return '|';}
\<\=            {count();return SE;}
\>\=            {count();return GE;}
\=\=            {count();return EQUAL;}
\!\=            {count();return DIFFERENT;}
[0-9]+          {count();yylval.ivalue=atoi(yytext);return INT;}

\"(\\.|[^\\"])*\" {count();yylval.string=strdup(yytext);return STRING;}

[a-zA-z_][a-zA-Z_0-9]* {count();yylval.string=strdup(yytext);return ID;}

[ \t\n]+        count();

<<EOF>>         return '$';

.               return ERROR;
%%

void count(){
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n'){
			column = 1;
      line++;
    }
		else count();
}


int yywrap(){
  return 1;
}
