#include "mate.h"
#include "handler.h"
#include <stdlib.h>

extern void am_parser_set_error(am_parser_t* parser, const char* message);

bool require_items_handle(am_parser_t* parser, const am_node_t* node, am_require_handler_t* handler, void* param) {
    if (!node) {
        return true;
    }

    am_require_context_t ctx;

    ctx.param = param;
    ctx.parser = parser;
    ctx.node = node;


    switch (node->mean) {
        case AM_S_REQUIRE_ITEM:
            ctx.id = node->str;
            ctx.uri = node->str2;
            return handler(&ctx);
        
        case AM_S_REQUIRE_ITEM_LIST:
            return require_items_handle(parser, node->a, handler, param) && require_items_handle(parser, node->b, handler, param);
        default:
            am_parser_set_error(parser, "node->mean must be AM_S_REQUIRE_ITEM or AM_S_REQUIRE_ITEM_LIST");
            return false;
    }
}

bool define_items_handle(am_parser_t* parser, const am_node_t* node, const am_define_handler_t* handler, void* param) {
    if (!node) {
        return true;
    }

    am_define_func_context_t ctx;

    ctx.param = param;
    ctx.parser = parser;
    ctx.node = node;

    switch(node->mean) {
        case AM_S_DEFINE:
            ctx.meta = node->a;
            am_node_t* right = node->b;

            switch (right->mean) {
                case AM_S_FUNC:
                    ctx.name = symbol_to_str(right->a);
                    ctx.arguments = right->b;
                    ctx.returns = right->c;
                    ctx.body = right->d;

                    bool result = handler->func_handler(&ctx);
                    free((void*)ctx.name);

                    return result;
                default:
                    am_parser_set_error(parser, "Invalid right side in define block");
                    return false;
            }

        case AM_S_DEFINES:
            return define_items_handle(parser, node->a, handler, param) && define_items_handle(parser, node->b, handler, param);

        default:
            am_parser_set_error(parser, "node->mean must be AM_S_DEFINE or AM_S_DEFINES");
            return false;
    }
}

bool am_handle_require_block(am_parser_t* parser, const am_node_t* node, am_require_handler_t* handler, void* param) {
    if (!node || node->mean != AM_S_ROOT) {
        am_parser_set_error(parser, "Null node given, or node->mean != AM_S_ROOT");
        return false;
    }

    if (!node->a) {
        return true; // Node has no require block
    }

    am_node_t* block_require = node->a;

    if (block_require->mean != AM_S_REQUIRE) {
        am_parser_set_error(parser, "Invalid require node");
        return false;
    }

    return require_items_handle(parser, block_require->a, handler, param) && require_items_handle(parser, block_require->b, handler, param);
}

bool am_handle_define_block(am_parser_t* parser, const am_node_t* node, const am_define_handler_t* handler, void* param) {
    if (!node || node->mean != AM_S_ROOT) {
        am_parser_set_error(parser, "Null node given, or node->mean != AM_S_ROOT");
        return false;
    }

    if (!node->b) {
        return true; // Node has node define blocks
    }

    am_node_t* block_define = node->b;

    if (block_define->mean != AM_S_DEFINES && block_define->mean != AM_S_DEFINE) {
        am_parser_set_error(parser, "Invalid define node");
        return false;
    }

    return define_items_handle(parser, block_define, handler, param);
}
