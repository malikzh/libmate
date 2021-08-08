#include "mate.h"
#include "handler.h"
#include <string.h>
#include <stdlib.h>

const char* symbol_to_str(const am_node_t* symbol_node) {
    if (!symbol_node || symbol_node->mean != AM_S_SYMBOL) {
        return NULL;
    }

    if (symbol_node->a == NULL) {
        return strdup(symbol_node->str);
    }

    const char* left  = symbol_to_str(symbol_node->a);
    const char* right = symbol_node->str;

    size_t left_size  = strlen(left);
    size_t right_size = strlen(right);

    char* combined = (char*)malloc(sizeof(char) * (left_size + right_size) + 2);
    const char* result = combined;
    
    memcpy(combined, left, left_size);
    combined += left_size;
    *combined = '.';
    ++combined;
    memcpy(combined, right, right_size);
    combined += right_size;
    *combined = '\0';

    free((void*)left);
    free((void*)right);

    return result;   
}
