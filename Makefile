all: compiler

compiler:y.tab.c lex.yy.c lib/Symbol.c lib/HashT.c
	gcc -o compiler y.tab.c -lfl lex.yy.c lib/Symbol.c lib/HashT.c lib/Stack.c

y.tab.c:TP2.y
	yacc -d TP2.y

lex.yy.c:TP2.l
	flex TP2.l

clean:
	rm -f compiler y.* lex.* *.o
