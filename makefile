# makefile - builds the C-- lexical analyzer (project part 1)

CC  = gcc
LEX = flex

part1: lex.yy.c
	$(CC) -o part1 lex.yy.c

lex.yy.c: part1.lex
	$(LEX) part1.lex

.PHONY: clean
clean:
	rm -f part1 lex.yy.c
