#include<iostream>
#include "mate.h"

int main(int argc, char** argv) {
    am_parser_t* parser = am_parser_create_from_str("test.mate", "define func Test() {} \n");
    am_parser_parse(parser);
    am_parser_destroy(parser);
    auto err = am_parser_get_error(parser);

    // AST root node
    am_node_t* root_node = am_parser_get_ast_root(parser);

    std::cout << (err != NULL ? err : "NULL" ) << std::endl;
    return 0;
}
