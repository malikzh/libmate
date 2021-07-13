#include "mate.h"
#include "processor.hpp"

bool am_parser_process_ast(am_parser_t* parser, const am_processor_t* processor, void* param) {
    const am_node_t* root = am_parser_get_ast_root(parser);

    if (!root) {
        return false;
    }

    // Handle root node
    if (root->mean != AM_S_ROOT) {
        ERROR("Invalid root node");
        return false;
    }

    if (root->a != NULL) {
        if (!pr_block_require(root->a, parser, processor, param)) {
            return false;
        }
    }

    return true;
}
