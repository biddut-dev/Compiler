%{
#include "compiler.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%%

mytype              { return MYTYPE; }
show                { return SHOW; }
if                  { return IF; }
else                { return ELSE; }

"<="                { return LE; }
">="                { return GE; }
"=="                { return EQ; }
"!="                { return NE; }
"&&"                { return AND; }
"||"                { return OR; }
"<"                 { return LT; }
">"                 { return GT; }
"!"                 { return NOT; }

"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return TIMES; }
"/"                 { return DIVIDE; }
"="                 { return '='; }
";"                 { return ';'; }
"("                 { return '('; }
")"                 { return ')'; }
"{"                 { return '{'; }
"}"                 { return '}'; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

[0-9]+ {
    yylval.num = atoi(yytext);
    return NUMBER;
}

[ \t\r\n]+          { /* ignore whitespace */ }
.                   { return yytext[0]; }

%%

int yywrap(void) {
    return 1;
}
