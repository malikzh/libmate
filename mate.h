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
        AM_S_ROOT,          // root node
        AM_S_IM,             // intermediate node
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
