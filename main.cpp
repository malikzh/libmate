#include<iostream>
#include<cstdio>
#include "mate.h"


bool parser_require(const am_require_context_t* ctx) {
    printf("I am a parsed require block!\nid: %s\nuri:%s\n", ctx->id, ctx->uri);
    return true;
}

bool parser_define_func(const am_define_func_context_t* ctx) {
    printf("\n---\ndefined func: %s\n---\n", ctx->name);
    return true;
}

int main(int argc, char** argv) {
    FILE* fd = fopen("./test.sample.mate", "r");

    if (!fd) {
        printf("Cannot open sample file");
        return 1;
    }


    am_parser_t* parser = am_parser_create_from_fd("test.sample.mate", fd);
    am_parser_parse(parser);
    
    auto err = am_parser_get_error(parser);

    // AST root node
    am_node_t* root_node = am_parser_get_ast_root(parser);

    am_handle_require_block(parser, root_node, &parser_require, NULL);

    am_define_handler_t h;
    h.func_handler = parser_define_func;

    am_handle_define_block(parser, root_node, &h, NULL);

    printf("\n\nError message: %s\n", am_parser_get_error(parser));

    am_parser_destroy(parser);
    return 0;
}
