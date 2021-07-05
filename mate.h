#ifndef LIBMATE_MATE_H
#define LIBMATE_MATE_H

#ifdef __cplusplus
    extern "C" {
#endif

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

// Node location
typedef struct {
    int first_line;
    int first_column;
    int last_line;
    int last_column;
} am_node_location_t;

// AST node
typedef enum {
    // Instructions
        AM_I_NOP = 0,            // No operation
        AM_I_RESOLVE_VARIABLE,   // Get variable value by name

        // Structure
        AM_S_ROOT,           // root node
        AM_S_SYMBOL,         // symbol part
        AM_S_ARRAY_ITEMS,
        AM_S_ARRAY,
        AM_S_STRING,
        AM_S_INT,
        AM_S_FLOAT,
        AM_S_TRUE,
        AM_S_FALSE,
        AM_S_NULL,
        AM_S_STRUCT_ITEMS,
        AM_S_STRUCT_ITEM,
        AM_S_STRUCT,
        AM_S_TYPENAME,
        AM_S_FUNCTION_ARGUMENT,
        AM_S_FUNCTION_ARGUMENTS,
        AM_S_FUNCTION_CALLBACK,
} am_node_mean_t;

typedef struct am_node_t_ {
    am_node_mean_t mean; // meaning of node
    am_node_location_t location;
    const char* str;

    struct am_node_t_* a;
    struct am_node_t_* b;
    struct am_node_t_* c;
} am_node_t;


// Parser
struct am_parser;
typedef struct am_parser am_parser_t;

am_parser_t* am_parser_create_from_fd(const char* filename, FILE* fd);
am_parser_t* am_parser_create_from_str(const char* filename, const char* input);
int am_parser_parse(am_parser_t* parser);
am_node_t* am_parser_get_ast_root(am_parser_t* parser);
void am_parser_destroy(am_parser_t* parser);

#ifdef __cplusplus
    }
#endif

#endif
