#ifndef SEMANTIC_H
#define SEMANTIC_H

#define MAX_SYMBOLS 100

// Symbol structure for symbol table
struct Symbol {
    char *name;
    char *type;
    int declared;
    int used;
    int line_declared;
    int line_used;
};

// Symbol table structure
struct SymbolTable {
    struct Symbol symbols[MAX_SYMBOLS];
    int count;
};

// External variables
extern struct SymbolTable symbol_table;
extern int semantic_errors;

// Core semantic analysis functions
void initializeSemanticAnalyzer();
void performSemanticAnalysis();
void cleanupSemanticAnalyzer();

// Symbol table management
void addSymbolDeclaration(char *name, char *type, int line);
void addSymbolUsage(char *name, int line);
int lookupSymbol(char *name);
char* getSymbolType(char *name);

// Type checking functions
int checkTypeCompatibility(char *type1, char *type2);
int checkScope(char *name, int line);
int validateFunctionCall(char *func_name, int param_count, int line);

// Analysis and reporting functions
void displaySymbolTable();
void checkUnusedVariables();
void checkUninitializedVariables();
void semanticError(char *msg, char *identifier, int line);
int getSemanticErrors();

#endif // SEMANTIC_H