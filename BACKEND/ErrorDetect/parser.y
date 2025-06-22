%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Symbol table structure
struct Symbol {
    char *name;
    char *type;
    int declared;
    int used;
    int line_declared;
};

struct SymbolTable {
    struct Symbol symbols[100];
    int count;
} symbol_table;

// Function prototypes
void insertSymbol(char *name, char *type, int line);
int lookupSymbol(char *name);
void checkUndeclaredVariables();
void semanticError(char *msg, char *var, int line);

extern int line_no;
extern int yylex();
extern char* yytext;

int syntax_errors = 0;
int semantic_errors = 0;
%}

%union {
    int ival;
    float fval;
    char *sval;
}

%token <ival> NUM
%token <fval> FLOAT_NUM
%token <sval> ID STRING
%token INT FLOAT CHAR VOID
%token IF ELSE WHILE FOR RETURN
%token ASSIGN PLUS MINUS MULT DIV
%token EQ NE LT GT LE GE
%token LPAREN RPAREN LBRACE RBRACE SEMI COMMA
%token ERROR

%type <sval> type_specifier

%start program

%%

program:
    declaration_list
    {
        printf("\n=== PARSING COMPLETED ===\n");
        checkUndeclaredVariables();
        printf("Syntax Errors: %d\n", syntax_errors);
        printf("Semantic Errors: %d\n", semantic_errors);
        
        if (syntax_errors == 0 && semantic_errors == 0) {
            printf("✅ Program is syntactically and semantically correct!\n");
        }
    }
    ;

declaration_list:
    declaration
    | declaration_list declaration
    ;

declaration:
    variable_declaration
    | function_declaration
    ;

variable_declaration:
    type_specifier ID SEMI
    {
        printf("Parsed variable declaration: %s %s\n", $1, $2);
        insertSymbol($2, $1, line_no);
    }
    | type_specifier ID ASSIGN expression SEMI
    {
        printf("Parsed variable declaration with assignment: %s %s\n", $1, $2);
        insertSymbol($2, $1, line_no);
    }
    ;

function_declaration:
    type_specifier ID LPAREN parameter_list RPAREN compound_statement
    {
        printf("Parsed function declaration: %s %s\n", $1, $2);
        insertSymbol($2, "function", line_no);
    }
    | VOID ID LPAREN parameter_list RPAREN compound_statement
    {
        printf("Parsed void function declaration: %s\n", $2);
        insertSymbol($2, "function", line_no);
    }
    ;

parameter_list:
    /* empty */
    | parameter_list_ne
    ;

parameter_list_ne:
    parameter
    | parameter_list_ne COMMA parameter
    ;

parameter:
    type_specifier ID
    {
        insertSymbol($2, $1, line_no);
    }
    ;

type_specifier:
    INT     { $$ = strdup("int"); }
    | FLOAT { $$ = strdup("float"); }
    | CHAR  { $$ = strdup("char"); }
    ;

compound_statement:
    LBRACE statement_list RBRACE
    | LBRACE RBRACE
    ;

statement_list:
    statement
    | statement_list statement
    ;

statement:
    expression_statement
    | compound_statement
    | selection_statement
    | iteration_statement
    | return_statement
    | variable_declaration
    ;

expression_statement:
    SEMI
    | expression SEMI
    ;

selection_statement:
    IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    ;

iteration_statement:
    WHILE LPAREN expression RPAREN statement
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    ;

return_statement:
    RETURN SEMI
    | RETURN expression SEMI
    ;

expression:
    assignment_expression
    ;

assignment_expression:
    logical_or_expression
    | ID ASSIGN assignment_expression
    {
        if (!lookupSymbol($1)) {
            semanticError("Undeclared variable", $1, line_no);
        } else {
            // Mark variable as used
            for (int i = 0; i < symbol_table.count; i++) {
                if (strcmp(symbol_table.symbols[i].name, $1) == 0) {
                    symbol_table.symbols[i].used = 1;
                    break;
                }
            }
        }
    }
    ;

logical_or_expression:
    logical_and_expression
    | logical_or_expression logical_and_expression
    ;

logical_and_expression:
    equality_expression
    | logical_and_expression equality_expression
    ;

equality_expression:
    relational_expression
    | equality_expression EQ relational_expression
    | equality_expression NE relational_expression
    ;

relational_expression:
    additive_expression
    | relational_expression LT additive_expression
    | relational_expression GT additive_expression
    | relational_expression LE additive_expression
    | relational_expression GE additive_expression
    ;

additive_expression:
    multiplicative_expression
    | additive_expression PLUS multiplicative_expression
    | additive_expression MINUS multiplicative_expression
    ;

multiplicative_expression:
    primary_expression
    | multiplicative_expression MULT primary_expression
    | multiplicative_expression DIV primary_expression
    ;

primary_expression:
    ID
    {
        if (!lookupSymbol($1)) {
            semanticError("Undeclared variable", $1, line_no);
        } else {
            // Mark variable as used
            for (int i = 0; i < symbol_table.count; i++) {
                if (strcmp(symbol_table.symbols[i].name, $1) == 0) {
                    symbol_table.symbols[i].used = 1;
                    break;
                }
            }
        }
    }
    | NUM
    | FLOAT_NUM
    | STRING
    | LPAREN expression RPAREN
    ;

%%

// Semantic Analysis Functions (Phase 3)
void insertSymbol(char *name, char *type, int line) {
    // Check for redeclaration
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            semanticError("Redeclaration of variable", name, line);
            return;
        }
    }
    
    // Insert new symbol
    if (symbol_table.count < 100) {
        symbol_table.symbols[symbol_table.count].name = strdup(name);
        symbol_table.symbols[symbol_table.count].type = strdup(type);
        symbol_table.symbols[symbol_table.count].declared = 1;
        symbol_table.symbols[symbol_table.count].used = 0;
        symbol_table.symbols[symbol_table.count].line_declared = line;
        symbol_table.count++;
        printf("✅ Symbol added: %s (%s) at line %d\n", name, type, line);
    } else {
        printf("❌ Symbol table overflow!\n");
    }
}

int lookupSymbol(char *name) {
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            return 1; // Found
        }
    }
    return 0; // Not found
}

void checkUndeclaredVariables() {
    printf("\n=== SYMBOL TABLE ===\n");
    printf("Name\t\tType\t\tDeclared\tUsed\t\tLine\n");
    printf("--------------------------------------------------------\n");
    
    for (int i = 0; i < symbol_table.count; i++) {
        printf("%-12s\t%-8s\t%s\t\t%s\t\t%d\n", 
               symbol_table.symbols[i].name,
               symbol_table.symbols[i].type,
               symbol_table.symbols[i].declared ? "Yes" : "No",
               symbol_table.symbols[i].used ? "Yes" : "No",
               symbol_table.symbols[i].line_declared);
               
        // Warning for unused variables
        if (symbol_table.symbols[i].declared && !symbol_table.symbols[i].used) {
            printf("⚠️  Warning: Variable '%s' declared but never used\n", 
                   symbol_table.symbols[i].name);
        }
    }
}

void semanticError(char *msg, char *var, int line) {
    printf("❌ Semantic Error at line %d: %s '%s'\n", line, msg, var);
    semantic_errors++;
}

int yyerror(const char *s) {
    printf("❌ Syntax Error at line %d: %s near '%s'\n", line_no, s, yytext);
    syntax_errors++;
    return 1;
}

int main() {
    printf("=== STATIC CODE ANALYZER ===\n");
    printf("Starting analysis...\n\n");
    
    symbol_table.count = 0;
    
    if (yyparse() == 0) {
        printf("\n✅ Parsing completed successfully!\n");
    } else {
        printf("\n❌ Parsing failed!\n");
    }
    
    return 0;
}