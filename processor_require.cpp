#include "mate.h"
#include "processor.hpp"

bool pr_block_require(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE) {
        ERROR("Invalid ast node on block_require");
        return false;
    }

    if (node->a != NULL) {
        if (!pr_require_item_list(node->a, parser, proc, param)) {
            return false;
        }
    }

    return true;
}

bool pr_require_item_list(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE_ITEM_LIST && node->mean != AM_S_REQUIRE_ITEM) {
        ERROR("Invalid ast node on require_item_list");
        return false;
    }

    if (node->mean == AM_S_REQUIRE_ITEM) {
        return pr_require_item(node, parser, proc, param);
    }

    auto a = node->a;
    auto b = node->b;

    if (a != NULL) {
        if (a->mean == AM_S_REQUIRE_ITEM_LIST) {
            if (!pr_require_item_list(a, parser, proc, param)) {
                return false;
            }
        } else {
            if (!pr_require_item(a, parser, proc, param)) {
                return false;
            }
        }
    }

    if (b != NULL) {
        if (!pr_require_item(b, parser, proc, param)) {
            return false;
        }
    }

    return true;
}

bool pr_require_item(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param) {
    if (node->mean != AM_S_REQUIRE_ITEM) {
        ERROR("Invalid ast node on require_item");
        return false;
    }

    // Call handler
    if (proc->import_module != NULL) {
        if (!proc->import_module(node->str, node->str2, parser, &node->location, param)) {
            return false;
        }
    } else {
        AM_DBG("WARNING: Module import has no handlers. Import arguments: %s, %s\n", node->str, node->str2);
    }

    return true;
}
