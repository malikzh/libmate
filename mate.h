#ifndef LIBMATE_MATE_H
#define LIBMATE_MATE_H

#ifdef __cplusplus
    extern "C" {
#endif

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

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
        AM_I_FUNC_CALL,
        AM_I_INDEX,
        AM_I_OBJECT_INDEX,
        AM_I_POST_INC,
        AM_I_POST_DEC,
        AM_I_PRE_INC,
        AM_I_PRE_DEC,
        AM_I_UPLUS,
        AM_I_UMINUS,
        AM_I_NOT,
        AM_I_CAST,
        AM_I_POW,
        AM_I_MUL,
        AM_I_DIV,
        AM_I_MOD,
        AM_I_ADD,
        AM_I_SUB,
        AM_I_GT,
        AM_I_LT,
        AM_I_LTE,
        AM_I_GTE,
        AM_I_EQ,
        AM_I_NEQ,
        AM_I_AND,
        AM_I_OR,
        AM_I_IMPLEMENTS,
        AM_I_TYPEOF,
        AM_I_METAOF,
        AM_I_TERNARY,
        AM_I_ASSIGN,
        AM_I_ASSIGN_ADD,
        AM_I_ASSIGN_SUB,
        AM_I_ASSIGN_MUL,
        AM_I_ASSIGN_DIV,
        AM_I_ASSIGN_MOD,
        AM_I_CONTINUE,
        AM_I_BREAK,
        AM_I_RETURN,

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
        AM_S_TYPENAME_ARRAY_OF,
        AM_S_TYPENAME_ARRAY,
        AM_S_TYPENAME_STRUCT,
        AM_S_TYPENAME_FUNC,
        AM_S_FUNCTION_ARGUMENT,
        AM_S_FUNCTION_ARGUMENTS,
        AM_S_FUNCTION_CALLBACK,
        AM_S_STATEMENTS,
        AM_S_DEFER,
        AM_S_IF,
        AM_S_DUMP,
        AM_S_CASE,
        AM_S_SWITCH_CASE,
        AM_S_SWITCH_CASE_LIST,
        AM_S_SWITCH,
        AM_S_SWITCH_DEFAULT,
        AM_S_VAR,
        AM_S_CONST,
        AM_S_WHILE,
        AM_S_FOR_HEAD,
        AM_S_FOR,
        AMS_S_FOREACH_HEAD,
        AM_S_EXPRESSIONS,
        AM_S_REQUIRE_ITEM,
        AM_S_REQUIRE_ITEM_LIST,
        AM_S_REQUIRE,
        AM_S_DEFINES,
        AM_S_FUNC,
        AM_S_META_TAG,
        AM_S_META_TAG_LIST,
        AM_S_DEFINE,
        AM_S_ALIAS,
        AM_S_NATIVE,
        AM_S_STRUCT_FIELD,
        AM_S_STRUCT_FIELD_LIST,
        AM_S_IFACE_FUNC,
        AM_S_FUNC_LIST,
        AM_S_IFACE,
} am_node_mean_t;

typedef struct am_node_t_ {
    am_node_mean_t mean; // meaning of node
    am_node_location_t location;
    const char* str;
    const char* str2;

    struct am_node_t_* a;
    struct am_node_t_* b;
    struct am_node_t_* c;
    struct am_node_t_* d;
} am_node_t;

// Parser
struct am_parser;
typedef struct am_parser am_parser_t;

// AST Processor
typedef struct {
    bool (*import_module)(const char* moduleName, const char* moduleUri, am_parser_t* parser, const am_node_location_t* location, void* param);
} am_processor_t;

#if defined(AM_DEBUG)
#   define AM_DBG(...) printf(__VA_ARGS__);
#else
#   define AM_DBG(...)
#endif

am_parser_t* am_parser_create_from_fd(const char* filename, FILE* fd);
am_parser_t* am_parser_create_from_str(const char* filename, const char* input);
int am_parser_parse(am_parser_t* parser);
am_node_t* am_parser_get_ast_root(am_parser_t* parser);
bool am_parser_process_ast(am_parser_t* parser, const am_processor_t* processor, void* param);
const char* am_parser_get_error(am_parser_t* parser);
void am_parser_destroy(am_parser_t* parser);

#ifdef __cplusplus
    }
#endif

#endif
