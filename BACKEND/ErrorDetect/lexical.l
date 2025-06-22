%{
#include "y.tab.h"
#include <string.h>
#include <stdlib.h>

int line_no = 1;
%}

%%
"int"           { return INT; }
"float"         { return FLOAT; }
"char"          { return CHAR; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"for"           { return FOR; }
"return"        { return RETURN; }
"void"          { return VOID; }

"="             { return ASSIGN; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"=="            { return EQ; }
"!="            { return NE; }
"<"             { return LT; }
">"             { return GT; }
"<="            { return LE; }
">="            { return GE; }

"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
";"             { return SEMI; }
","             { return COMMA; }

[0-9]+          { 
                  yylval.ival = atoi(yytext); 
                  return NUM; 
                }

[0-9]+\.[0-9]+  { 
                  yylval.fval = atof(yytext); 
                  return FLOAT_NUM; 
                }

[a-zA-Z_][a-zA-Z0-9_]* { 
                  yylval.sval = strdup(yytext); 
                  return ID; 
                }

\"[^\"]*\"      { 
                  yylval.sval = strdup(yytext); 
                  return STRING; 
                }

[ \t]           ; // Ignore whitespace

\n              { line_no++; }

\/\/.*          ; // Single line comments

\/\*([^*]|\*+[^*/])*\*+\/ ; // Multi-line comments

.               { 
                  printf("Lexical Error at line %d: Invalid character '%s'\n", 
                         line_no, yytext); 
                  return ERROR; 
                }

%%

int yywrap() {
    return 1;
}