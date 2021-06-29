#ifndef LIBMATE_MATE_H
#define LIBMATE_MATE_H

#ifdef __cplusplus
    extern "C" {
#endif

#ifndef AM_INCLUDE_STDIO
    #include <stdio.h>
#endif

// Node location
typedef struct {
    int first_line;
    int first_column;
    int last_line;
    int last_column;
} am_node_location_t;

// AST node
typedef struct am_node_t_ {
    enum {
        OBJECT_ID,
    } type;
    am_node_location_t location;
} am_node_t;


// Parser
struct am_parser;
typedef struct am_parser am_parser_t;

am_parser_t* am_parser_create_from_fd(const char* filename, FILE* fd);
am_parser_t* am_parser_create_from_str(const char* filename, const char* input);
int am_parser_parse(am_parser_t* parser);
void am_parser_destroy(am_parser_t* parser);

#ifdef __cplusplus
    }
#endif

#endif
