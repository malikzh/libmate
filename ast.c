#include <stdlib.h>
#include "mate.h"
#include "ast.h"

am_node_t* ast_create_node(am_node_mean_t meaning, const am_node_location_t* location, am_node_t* a, am_node_t* b, am_node_t* c, const char* str) {
    am_node_t* n = (am_node_t*)calloc(1, sizeof(am_node_t));
    n->mean = meaning;
    n->a = a;
    n->b = b;
    n->c = c;
    n->str = str;

    // copy location
    n->location.first_column = location->first_column;
    n->location.last_column = location->last_column;
    n->location.first_line = location->first_line;
    n->location.last_line = location->last_line;

    return n;
}
