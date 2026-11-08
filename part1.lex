%{
/*
 * part1.lex - Lexical analyzer for C--
 * 046266 Compilation Methods - Project, Part 1
 *
 * Reads a C-- program from stdin and prints its tokens to stdout.
 * Whitespace and symbols are copied to the output unchanged,
 * comments are dropped, and an illegal lexeme stops the run with exit code 1.
 */
#include <stdio.h>
#include <stdlib.h>
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput

whitespace  [ \t\r\n]
symbol      [\[\](){},;:]

id          [a-zA-Z][a-zA-Z0-9_]*
integernum  [0-9]+
realnum     [0-9]+\.[0-9]+
str         \"([^"\\\r\n]|\\[tn"])*\"

%%

int|float|void|write|read|while|do|if|then|else|return {
                printf("<%s>", yytext);
            }

{realnum}   { printf("<realnum,%s>", yytext); }
{integernum} { printf("<integernum,%s>", yytext); }
{id}        { printf("<id,%s>", yytext); }
{str}       { printf("<str,%.*s>", (int)(yyleng - 2), yytext + 1); /* drop the outer quotes */ }

"=="|"<>"|"<="|">="|"<"|">" { printf("<relop,%s>", yytext); }
"+"|"-"     { printf("<addop,%s>", yytext); }
"*"|"/"     { printf("<mulop,%s>", yytext); }
"="         { printf("<assign,%s>", yytext); }
"&&"        { printf("<and,%s>", yytext); }
"||"        { printf("<or,%s>", yytext); }
"!"         { printf("<not,%s>", yytext); }

{symbol}    { ECHO; }
{whitespace} { ECHO; }
"#"[^\r\n]* { /* comment: ignored */ }

.           {
                printf("\nLexical error: '%s' in line number %d\n", yytext, yylineno);
                exit(1);
            }

%%

int main(void)
{
    yylex();
    return 0;
}
