#include "mate.h"
#include "processor.hpp"

void pr_block_require(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE) {
        ERROR("Invalid ast node on block_require");
        return;
    }

    if (node->a != NULL) {
        pr_require_item_list(node->a, parser, proc, param);
    }
}

void pr_require_item_list(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE_ITEM_LIST) {
        ERROR("Invalid ast node on require_item_list");
        return;
    }

    auto a = node->a;
    auto b = node->b;

    if (a != NULL) {
        if (a->mean == AM_S_REQUIRE_ITEM_LIST) {
            pr_require_item_list(a, parser, proc, param);
        } else {
            pr_require_item(a, parser, proc, param);
        }
    }

    if (b != NULL) {
        pr_require_item(b, parser, proc, param);
    }
}

void pr_require_item(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE_ITEM) {
        ERROR("Invalid ast node on require_item");
        return;
    }

    // Call handler
    if (proc->import_module != NULL) {
        proc->import_module(node->str, node->str2, parser, &node->location, param);
    } else {
        AM_DBG("WARNING: Module import has no handlers. Import arguments: %s, %s\n", node->str, node->str2);
    }
}
