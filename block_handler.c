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

            if (!handler) {
                am_parser_set_error(parser, "Require items handler is not set");
                return false;
            }

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

    switch(node->mean) {
        case AM_S_DEFINE: {
            am_node_t* right = node->b;

            switch (right->mean) {
                case AM_S_FUNC: {
                    am_define_func_context_t ctx;

                    ctx.param = param;
                    ctx.parser = parser;
                    ctx.node = node;
                    ctx.meta = node->a;
                    ctx.name = symbol_to_str(right->a);
                    ctx.arguments = right->b;
                    ctx.returns = right->c;
                    ctx.body = right->d;

                    if (!handler->func_handler) {
                        am_parser_set_error(parser, "Function handler in define block is not set");
                        return false;
                    }

                    bool result = handler->func_handler(&ctx);
                    free((void*)ctx.name);

                    return result;
                }
                
                case AM_S_CONST: {
                    am_define_const_context_t ctx;

                    ctx.param = param;
                    ctx.parser = parser;
                    ctx.node = node;
                    ctx.meta = node->a;
                    ctx.name = right->str;
                    ctx.value = right->a;

                    if (!handler->const_handler) {
                        am_parser_set_error(parser, "Const handler in define block is not set");
                        return false;
                    }

                    return handler->const_handler(&ctx);
                }

                case AM_S_ALIAS: {
                    am_define_alias_context_t ctx;

                    ctx.param = param;
                    ctx.parser = parser;
                    ctx.node = node;
                    ctx.meta = node->a;
                    ctx.name = right->str;
                    ctx.types = right->a;

                    if (!handler->alias_handler) {
                        am_parser_set_error(parser, "Alias handler in define block is not set");
                        return false;
                    }

                    return handler->alias_handler(&ctx);
                }

                case AM_S_NATIVE: {
                    am_define_native_context_t ctx;

                    ctx.param = param;
                    ctx.parser = parser;
                    ctx.node = node;
                    ctx.meta = node->a;
                    ctx.name = right->str;
                    ctx.returns = right->b;
                    ctx.arguments = right->a;

                    if (!handler->native_handler) {
                        am_parser_set_error(parser, "Native handler in define block is not set");
                        return false;
                    }

                    return handler->native_handler(&ctx);
                }

                default:
                    am_parser_set_error(parser, "Invalid right side in define block");
                    return false;
            }
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

    if (!handler) {
        am_parser_set_error(parser, "Handler for define block is null");
        return false;
    }

    return define_items_handle(parser, block_define, handler, param);
}
