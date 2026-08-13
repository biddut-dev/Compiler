%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
int yyerror(char *s);

typedef struct Symbol {
    char *name;
    int value;
} Symbol;

#define MAX_SYMBOLS 100
Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

int findSymbolIndex(char *name);
void addSymbol(char *name, int value);
int getSymbolValue(char *name);


#define MAX_IF_DEPTH 100
int execStack[MAX_IF_DEPTH];
int ifDepth = 0;

int currentExecution(void);
void pushExecution(int condition);
void popExecution(void);

%}

%union {
    char *str;
    int num;
}

%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT
%right UMINUS

%token MYTYPE SHOW IF ELSE
%token <str> IDENTIFIER
%token <num> NUMBER

%token PLUS MINUS TIMES DIVIDE
%token LT LE GT GE EQ NE
%token AND OR NOT

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%type <num> expression

%%

program:
    statements
    ;

statements:
      statements statement
    | statement
    ;

statement:
      MYTYPE IDENTIFIER ';'
      {
          if (currentExecution()) {
              if (findSymbolIndex($2) != -1)
                  printf("Warning: %s is already declared.\n", $2);
              else {
                  addSymbol($2, 0);
                  printf("Declared %s\n", $2);
              }
          }
          free($2);
      }

    | IDENTIFIER '=' expression ';'
      {
          if (currentExecution()) {
              if (findSymbolIndex($1) == -1)
                  printf("Error: Variable %s is not declared.\n", $1);
              else {
                  addSymbol($1, $3);
                  printf("Assigned %d to variable %s\n", $3, $1);
              }
          }
          free($1);
      }

    | SHOW '(' IDENTIFIER ')' ';'
      {
          if (currentExecution()) {
              if (findSymbolIndex($3) == -1)
                  printf("Error: Variable %s is not declared.\n", $3);
              else
                  printf("Displaying value of %s: %d\n",
                         $3, getSymbolValue($3));
          }
          free($3);
      }

    | if_prefix block %prec LOWER_THAN_ELSE
      {
          popExecution();
      }

    | if_prefix block else_prefix block
      {
          popExecution();
      }

    | expression ';'
      {
          if (currentExecution())
              printf("Expression result: %d\n", $1);
      }
    ;

if_prefix:
    IF '(' expression ')'
    {
        pushExecution($3 != 0);
    }
    ;

else_prefix:
    ELSE
    {
        /* Switch from the IF branch to the ELSE branch. */
        int old = execStack[ifDepth - 1];
        int parent = (ifDepth >= 2) ? execStack[ifDepth - 2] : 1;
        execStack[ifDepth - 1] = parent && !old;
    }
    ;

block:
    '{' statements '}'
    ;

expression:
      expression PLUS expression    { $$ = $1 + $3; }
    | expression MINUS expression   { $$ = $1 - $3; }
    | expression TIMES expression   { $$ = $1 * $3; }
    | expression DIVIDE expression
      {
          if ($3 == 0) {
              yyerror("Division by zero");
              $$ = 0;
          } else
              $$ = $1 / $3;
      }

    | expression LT expression      { $$ = $1 < $3; }
    | expression LE expression      { $$ = $1 <= $3; }
    | expression GT expression      { $$ = $1 > $3; }
    | expression GE expression      { $$ = $1 >= $3; }
    | expression EQ expression      { $$ = $1 == $3; }
    | expression NE expression      { $$ = $1 != $3; }

    | expression AND expression     { $$ = ($1 != 0) && ($3 != 0); }
    | expression OR expression      { $$ = ($1 != 0) || ($3 != 0); }
    | NOT expression                { $$ = !$2; }
    | MINUS expression %prec UMINUS { $$ = -$2; }

    | NUMBER                        { $$ = $1; }
    | IDENTIFIER
      {
          if (findSymbolIndex($1) == -1) {
              if (currentExecution())
                  printf("Error: Variable %s is not declared.\n", $1);
              $$ = 0;
          } else
              $$ = getSymbolValue($1);
          free($1);
      }
    | '(' expression ')'           { $$ = $2; }
    ;

%%

int yyerror(char *s) {
    printf("Error: %s\n", s);
    return 0;
}

int main(void) {
    printf("Mini Language Interpreter\n");
    printf("Features: variables, arithmetic, comparisons, boolean operators, IF/ELSE\n\n");
    yyparse();
    return 0;
}

int findSymbolIndex(char *name) {
    for (int i = 0; i < symbolCount; i++)
        if (strcmp(symbolTable[i].name, name) == 0)
            return i;
    return -1;
}

void addSymbol(char *name, int value) {
    int index = findSymbolIndex(name);

    if (index == -1) {
        if (symbolCount < MAX_SYMBOLS) {
            symbolTable[symbolCount].name = strdup(name);
            symbolTable[symbolCount].value = value;
            symbolCount++;
        } else {
            printf("Symbol table full!\n");
        }
    } else {
        symbolTable[index].value = value;
    }
}

int getSymbolValue(char *name) {
    int index = findSymbolIndex(name);
    if (index != -1)
        return symbolTable[index].value;

    printf("Error: Symbol %s not found!\n", name);
    return 0;
}

int currentExecution(void) {
    if (ifDepth == 0)
        return 1;
    return execStack[ifDepth - 1];
}

void pushExecution(int condition) {
    int parent = (ifDepth == 0) ? 1 : execStack[ifDepth - 1];

    if (ifDepth < MAX_IF_DEPTH)
        execStack[ifDepth++] = parent && condition;
}

void popExecution(void) {
    if (ifDepth > 0)
        ifDepth--;
}
