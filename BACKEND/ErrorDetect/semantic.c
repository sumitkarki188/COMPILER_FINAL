#include "semantic.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global symbol table
struct SymbolTable symbol_table;
int semantic_errors = 0;

// Initialize the semantic analyzer
void initializeSemanticAnalyzer() {
    symbol_table.count = 0;
    semantic_errors = 0;
    printf("=== PHASE 3: SEMANTIC ANALYSIS INITIALIZED ===\n");
}

// Add a symbol declaration to the symbol table
void addSymbolDeclaration(char *name, char *type, int line) {
    // Check for redeclaration
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            semanticError("Redeclaration of variable", name, line);
            return;
        }
    }
    
    // Insert new symbol
    if (symbol_table.count < MAX_SYMBOLS) {
        symbol_table.symbols[symbol_table.count].name = strdup(name);
        symbol_table.symbols[symbol_table.count].type = strdup(type);
        symbol_table.symbols[symbol_table.count].declared = 1;
        symbol_table.symbols[symbol_table.count].used = 0;
        symbol_table.symbols[symbol_table.count].line_declared = line;
        symbol_table.symbols[symbol_table.count].line_used = -1;
        symbol_table.count++;
        printf("✅ Symbol declared: %s (%s) at line %d\n", name, type, line);
    } else {
        printf("❌ Symbol table overflow! Maximum %d symbols allowed.\n", MAX_SYMBOLS);
    }
}

// Add a symbol usage (mark variable as used)
void addSymbolUsage(char *name, int line) {
    int found = 0;
    
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            symbol_table.symbols[i].used = 1;
            if (symbol_table.symbols[i].line_used == -1) {
                symbol_table.symbols[i].line_used = line;
            }
            found = 1;
            break;
        }
    }
    
    if (!found) {
        semanticError("Undeclared variable", name, line);
    }
}

// Lookup a symbol in the symbol table
int lookupSymbol(char *name) {
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            return 1; // Found
        }
    }
    return 0; // Not found
}

// Get symbol type
char* getSymbolType(char *name) {
    for (int i = 0; i < symbol_table.count; i++) {
        if (strcmp(symbol_table.symbols[i].name, name) == 0) {
            return symbol_table.symbols[i].type;
        }
    }
    return NULL; // Not found
}

// Check for type compatibility
int checkTypeCompatibility(char *type1, char *type2) {
    if (strcmp(type1, type2) == 0) {
        return 1; // Same types are compatible
    }
    
    // Allow int and float compatibility (with warning)
    if ((strcmp(type1, "int") == 0 && strcmp(type2, "float") == 0) ||
        (strcmp(type1, "float") == 0 && strcmp(type2, "int") == 0)) {
        return 2; // Compatible with warning
    }
    
    return 0; // Incompatible
}

// Perform comprehensive semantic analysis
void performSemanticAnalysis() {
    printf("\n=== PERFORMING SEMANTIC ANALYSIS ===\n");
    
    displaySymbolTable();
    checkUnusedVariables();
    checkUninitializedVariables();
    
    printf("\n=== SEMANTIC ANALYSIS RESULTS ===\n");
    printf("Semantic Errors: %d\n", semantic_errors);
    
    if (semantic_errors == 0) {
        printf("✅ Program is semantically correct!\n");
    } else {
        printf("❌ Program has semantic errors!\n");
    }
}

// Display the symbol table
void displaySymbolTable() {
    printf("\n=== SYMBOL TABLE ===\n");
    printf("%-15s %-10s %-10s %-8s %-12s %-10s\n", 
           "Name", "Type", "Declared", "Used", "Decl_Line", "Used_Line");
    printf("------------------------------------------------------------------------\n");
    
    for (int i = 0; i < symbol_table.count; i++) {
        printf("%-15s %-10s %-10s %-8s %-12d %-10d\n", 
               symbol_table.symbols[i].name,
               symbol_table.symbols[i].type,
               symbol_table.symbols[i].declared ? "Yes" : "No",
               symbol_table.symbols[i].used ? "Yes" : "No",
               symbol_table.symbols[i].line_declared,
               symbol_table.symbols[i].line_used != -1 ? symbol_table.symbols[i].line_used : 0);
    }
}

// Check for unused variables
void checkUnusedVariables() {
    printf("\n=== CHECKING FOR UNUSED VARIABLES ===\n");
    int unused_count = 0;
    
    for (int i = 0; i < symbol_table.count; i++) {
        if (symbol_table.symbols[i].declared && 
            !symbol_table.symbols[i].used && 
            strcmp(symbol_table.symbols[i].type, "function") != 0) {
            
            printf("⚠️  Warning: Variable '%s' declared at line %d but never used\n", 
                   symbol_table.symbols[i].name, 
                   symbol_table.symbols[i].line_declared);
            unused_count++;
        }
    }
    
    if (unused_count == 0) {
        printf("✅ No unused variables found\n");
    } else {
        printf("Found %d unused variable(s)\n", unused_count);
    }
}

// Check for uninitialized variables (basic check)
void checkUninitializedVariables() {
    printf("\n=== CHECKING FOR POTENTIAL UNINITIALIZED USAGE ===\n");
    // This is a simplified check - in a real analyzer, you'd need flow analysis
    
    for (int i = 0; i < symbol_table.count; i++) {
        if (symbol_table.symbols[i].used && 
            symbol_table.symbols[i].line_used < symbol_table.symbols[i].line_declared) {
            
            printf("⚠️  Warning: Variable '%s' may be used before declaration\n", 
                   symbol_table.symbols[i].name);
        }
    }
    
    printf("✅ Basic initialization check completed\n");
}

// Check scope rules (simplified - global scope only in this implementation)
int checkScope(char *name, int line) {
    // In a full implementation, you'd maintain scope stack
    // For now, we only support global scope
    return lookupSymbol(name);
}

// Validate function calls (basic implementation)
int validateFunctionCall(char *func_name, int param_count, int line) {
    if (!lookupSymbol(func_name)) {
        semanticError("Undeclared function", func_name, line);
        return 0;
    }
    
    char *type = getSymbolType(func_name);
    if (strcmp(type, "function") != 0) {
        semanticError("Attempting to call non-function", func_name, line);
        return 0;
    }
    
    // In a full implementation, you'd check parameter count and types
    return 1;
}

// Report semantic errors
void semanticError(char *msg, char *identifier, int line) {
    printf("❌ Semantic Error at line %d: %s '%s'\n", line, msg, identifier);
    semantic_errors++;
}

// Get total semantic errors
int getSemanticErrors() {
    return semantic_errors;
}

// Clean up memory (call at program end)
void cleanupSemanticAnalyzer() {
    for (int i = 0; i < symbol_table.count; i++) {
        free(symbol_table.symbols[i].name);
        free(symbol_table.symbols[i].type);
    }
    symbol_table.count = 0;
}