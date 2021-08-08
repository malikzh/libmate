#include <stdlib.h>
#include "mate.h"
#include "ast.h"

am_node_t* ast_create_node(am_node_mean_t meaning, const am_node_location_t* location, am_node_t* a, am_node_t* b, am_node_t* c, am_node_t* d, const char* str, const char* str2) {
    am_node_t* n = (am_node_t*)calloc(1, sizeof(am_node_t));
    n->mean = meaning;
    n->a = a;
    n->b = b;
    n->c = c;
    n->d = d;
    n->str = str;
    n->str2 = str2;

    // copy location
    n->location.first_column = location->first_column;
    n->location.last_column = location->last_column;
    n->location.first_line = location->first_line;
    n->location.last_line = location->last_line;

    return n;
}

void ast_free(am_node_t* root) {
    if (root == NULL) return;

    ast_free(root->a);
    ast_free(root->b);
    ast_free(root->c);
    ast_free(root->d);

    // TODO: Fix memory leaks in lexer.c strbuffer.c, remove string copying
/*
    if (root->str != NULL) {
        free((void*)root->str);
    }

    if (root->str2 != NULL) {
        free((void*)root->str2);
    }
*/
    free(root);
}
