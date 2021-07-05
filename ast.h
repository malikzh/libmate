#ifndef LIBAMTE_AST_H
#define LIBAMTE_AST_H

am_node_t* ast_create_node(am_node_mean_t meaning, const am_node_location_t* location, am_node_t* a, am_node_t* b, am_node_t* c, const char* str);

#endif
